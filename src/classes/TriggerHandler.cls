public virtual class TriggerHandler {
  // static map of handlername, times run() was invoked
  private static Map<String, LoopCount> loopCountMap;
  private static Set<String> bypassedHandlers;

  // the current context of the trigger, overridable in tests
  @TestVisible
  private TriggerContext context;

  // the current context of the trigger, overridable in tests
  @TestVisible
  private Boolean isTriggerExecuting;

  // profile based trigger handler overrides
  @TestVisible
  private static List<Trigger_Handler_Override__mdt> pbthOverridesForTest;

  // get list of nonmanaged Apex classes (consider moving this to a utils class)
  private static List<ApexClass> nonManagedApexClasses {
    get {
      if (nonManagedApexClasses == null) {
        nonManagedApexClasses = [
          SELECT Name
          FROM ApexClass
          WHERE NamespacePrefix = NULL
        ];
      }
      return nonManagedApexClasses;
    }
    set;
  }

  // get logged in user profile (consider moving this to a utils class)
  private static Profile loggedInUserProfile {
    get {
      if (loggedInUserProfile == null) {
        loggedInUserProfile = [
          SELECT Id, Name
          FROM Profile
          WHERE Id = :Userinfo.getProfileId()
        ];
      }
      return loggedInUserProfile;
    }
    set;
  }

  // static initialization
  static {
    loopCountMap = new Map<String, LoopCount>();
    bypassedHandlers = new Set<String>();
  }

  // constructor
  public TriggerHandler() {
    this.setTriggerContext();
  }
  public TriggerHandler(String handlerName) {
    this.handlerName = handlerName;
    this.setTriggerContext();
  }
  /***************************************
   * public instance methods
   ***************************************/

  // main method that will be called during execution
  public void run() {
    if (!validateRun())
      return;

    addToLoopCount();

    // dispatch to the correct handler method
    if (this.context == TriggerContext.BEFORE_INSERT) {
      this.beforeInsert();
    } else if (this.context == TriggerContext.BEFORE_UPDATE) {
      this.beforeUpdate();
    } else if (this.context == TriggerContext.BEFORE_DELETE) {
      this.beforeDelete();
    } else if (this.context == TriggerContext.AFTER_INSERT) {
      this.afterInsert();
    } else if (this.context == TriggerContext.AFTER_UPDATE) {
      this.afterUpdate();
    } else if (this.context == TriggerContext.AFTER_DELETE) {
      this.afterDelete();
    } else if (this.context == TriggerContext.AFTER_UNDELETE) {
      this.afterUndelete();
    }
  }

  public void setMaxLoopCount(Integer max) {
    String handlerName = getHandlerName();
    if (!TriggerHandler.loopCountMap.containsKey(handlerName)) {
      TriggerHandler.loopCountMap.put(handlerName, new LoopCount(max));
    } else {
      TriggerHandler.loopCountMap.get(handlerName).setMax(max);
    }
  }

  public void clearMaxLoopCount() {
    this.setMaxLoopCount(-1);
  }

  /***************************************
   * public static methods
   ***************************************/

  public static void bypass(String handlerName) {
    TriggerHandler.bypassedHandlers.add(handlerName);
  }

  public static void clearBypass(String handlerName) {
    TriggerHandler.bypassedHandlers.remove(handlerName);
  }

  public static Boolean isBypassed(String handlerName) {
    return TriggerHandler.bypassedHandlers.contains(handlerName);
  }

  public static void clearAllBypasses() {
    TriggerHandler.bypassedHandlers.clear();
  }

  /***************************************
   * private instancemethods
   ***************************************/

  @TestVisible
  private void setTriggerContext() {
    this.setTriggerContext(null, false);
  }

  @TestVisible
  private void setTriggerContext(String ctx, Boolean testMode) {
    if (!Trigger.isExecuting && !testMode) {
      this.isTriggerExecuting = false;
      return;
    } else {
      this.isTriggerExecuting = true;
    }

    if (
      (Trigger.isExecuting && Trigger.isBefore && Trigger.isInsert) ||
      (ctx != null &&
      ctx == 'before insert')
    ) {
      this.context = TriggerContext.BEFORE_INSERT;
    } else if (
      (Trigger.isExecuting && Trigger.isBefore && Trigger.isUpdate) ||
      (ctx != null &&
      ctx == 'before update')
    ) {
      this.context = TriggerContext.BEFORE_UPDATE;
    } else if (
      (Trigger.isExecuting && Trigger.isBefore && Trigger.isDelete) ||
      (ctx != null &&
      ctx == 'before delete')
    ) {
      this.context = TriggerContext.BEFORE_DELETE;
    } else if (
      (Trigger.isExecuting && Trigger.isAfter && Trigger.isInsert) ||
      (ctx != null &&
      ctx == 'after insert')
    ) {
      this.context = TriggerContext.AFTER_INSERT;
    } else if (
      (Trigger.isExecuting && Trigger.isAfter && Trigger.isUpdate) ||
      (ctx != null &&
      ctx == 'after update')
    ) {
      this.context = TriggerContext.AFTER_UPDATE;
    } else if (
      (Trigger.isExecuting && Trigger.isAfter && Trigger.isDelete) ||
      (ctx != null &&
      ctx == 'after delete')
    ) {
      this.context = TriggerContext.AFTER_DELETE;
    } else if (
      (Trigger.isExecuting && Trigger.isAfter && Trigger.isUndelete) ||
      (ctx != null &&
      ctx == 'after undelete')
    ) {
      this.context = TriggerContext.AFTER_UNDELETE;
    }
  }

  // increment the loop count
  @TestVisible
  private void addToLoopCount() {
    String handlerName = getHandlerName();
    if (TriggerHandler.loopCountMap.containsKey(handlerName)) {
      Boolean exceeded = TriggerHandler.loopCountMap.get(handlerName)
        .increment();
      if (exceeded) {
        Integer max = TriggerHandler.loopCountMap.get(handlerName).max;
        throw new TriggerHandlerException(
          'Maximum loop count of ' +
          String.valueOf(max) +
          ' reached in ' +
          handlerName
        );
      }
    }
  }

  // make sure this trigger should continue to run
  // (Modified by Kevin Antonioli (braveitnow@pm.me) to allow granular admin control over which handlers run)
  @TestVisible
  private Boolean validateRun() {
    if (!this.isTriggerExecuting || this.context == null) {
      throw new TriggerHandlerException(
        'Trigger handler called outside of Trigger execution'
      );
    }
    Set<String> controlFlagBypassedHandlers = new Set<String>();

    // comma delimited list of trigger handlers to disable defined in custom setting:
    String bypassedHandlersString = Control_Flags__c.getOrgDefaults()
      .NonManaged_TriggerHandlers_To_Disable__c;

    Boolean allHandlersToBeDisabled = false;
    if (
      Control_Flags__c.getOrgDefaults().Disable_NonManaged_TriggerHandlers__c
    ) {
      // disable all nonmanaged triggers for all profiles if custom setting flag is checked
      for (ApexClass apexClass : nonManagedApexClasses) {
        Triggerhandler.bypassedHandlers.add(apexClass.Name);
      }
      allHandlersToBeDisabled = true;
    } else if (bypassedHandlersString != null) {
      // disable specific nonmanaged triggers for all profiles
      for (String tHandlerString : bypassedHandlersString.split(',')) {
        Triggerhandler.bypassedHandlers.add(tHandlerString);
      }
    }

    // if control flag bypass all field is not checked:
    if (!allHandlersToBeDisabled) {
      // get any granular overrides configured based on profile:
      for (
        Trigger_Handler_Override__mdt thOverride : !Test.isRunningTest()
          ? Trigger_Handler_Override__mdt.getAll().values()
          : pbthOverridesForTest
      ) {
        String tHandlersToDisable = thOverride.NonManaged_TriggerHandlers_To_Disable__c;
        if (
          thOverride.Active__c &&
          thOverride.Profile__c == loggedInUserProfile.Name
        ) {
          if (thOverride.Disable_NonManaged_TriggerHandlers__c) {
            // disable all nonmanaged triggers for logged in user profile:
            for (ApexClass apexClass : nonManagedApexClasses) {
              Triggerhandler.bypassedHandlers.add(apexClass.Name);
            }
          } else if (tHandlersToDisable != null) {
            // disable specific nonmanaged triggers for logged in user profile:
            for (String tHandlerString : tHandlersToDisable.split(',')) {
              Triggerhandler.bypassedHandlers.add(tHandlerString.trim());
            }
          }
        }
      }
    }

    return !TriggerHandler.bypassedHandlers.contains(getHandlerName());
  }

  @TestVisible
  private String getHandlerName() {
    if (String.isBlank(this.handlerName)) {
      this.handlerName = String.valueOf(this)
        .substring(0, String.valueOf(this).indexOf(':'));
    }
    return handlerName;
  }
  private String handlerName { get; set; }

  /***************************************
   * context methods
   ***************************************/

  // context-specific methods for override
  @TestVisible
  protected virtual void beforeInsert() {
  }
  @TestVisible
  protected virtual void beforeUpdate() {
  }
  @TestVisible
  protected virtual void beforeDelete() {
  }
  @TestVisible
  protected virtual void afterInsert() {
  }
  @TestVisible
  protected virtual void afterUpdate() {
  }
  @TestVisible
  protected virtual void afterDelete() {
  }
  @TestVisible
  protected virtual void afterUndelete() {
  }

  /***************************************
   * inner classes
   ***************************************/

  // inner class for managing the loop count per handler
  @TestVisible
  private class LoopCount {
    private Integer max;
    private Integer count;

    public LoopCount() {
      this.max = 5;
      this.count = 0;
    }

    public LoopCount(Integer max) {
      this.max = max;
      this.count = 0;
    }

    public Boolean increment() {
      this.count++;
      return this.exceeded();
    }

    public Boolean exceeded() {
      if (this.max < 0)
        return false;
      if (this.count > this.max) {
        return true;
      }
      return false;
    }

    public Integer getMax() {
      return this.max;
    }

    public Integer getCount() {
      return this.count;
    }

    public void setMax(Integer max) {
      this.max = max;
    }
  }

  // possible trigger contexts
  @TestVisible
  private enum TriggerContext {
    BEFORE_INSERT,
    BEFORE_UPDATE,
    BEFORE_DELETE,
    AFTER_INSERT,
    AFTER_UPDATE,
    AFTER_DELETE,
    AFTER_UNDELETE
  }

  // exception class
  public class TriggerHandlerException extends Exception {
  }
}
