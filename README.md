# SFDC trigger framework

Overview:
This is Kevin Ohara's Trigger Handler framework, with a few upgrades:

Admin-configurable bypasses via custom setting/custom metadata type (I added these to empower non-dev admins to bypass handlers)
Added constructor for performance boost (thanks to Mr Barsotti)

## Setup: ## 
Create a Trigger_Handler_Bypass__mdt record for every one of your org's current non-managed trigger handlers.

Name/Label: Trigger Handler Name (ex: AccountTriggerHandler)

Active__c: false (change to true if you want to apply an org-wide, profile-based, or user-based bypass for the given Trigger Handler Name)

Here's a class and accompanying execute anonymous script to make this way faster than doing it in the UI: https://github.com/kevina-code/DeployCustomMetadata

Then, going forward, when someone creates a new trigger handler apex class in your org, create a  Trigger_Handler_Bypass__mdt record for that handler as well.


## Scenarios: ## 
**Global bypasses:**

##  disable all non-managed triggers for all users
1. Set the Control_Flag__c.Disable_Triggers__c organization default to true
2. Set the Active__c checkbox to true on every Trigger_Handler_Bypass__mdt record

##  disable all non-managed triggers for specific profile(s):
Set the Control_Flag__c.Disable_Triggers__c organization default to false
Create a Control_Flag__c instance for the desired profile(s)
Set Disable_Triggers__c to true on those instances
Set the Active__c checkbox to true on every Trigger_Handler_Bypass__mdt record

**Scenario 3:** disable all non-managed triggers for specific user(s):
Set the Control_Flag__c.Disable_Triggers__c organization default to false
Create a Control_Flag__c instance for the desired user(s)
Set Disable_Triggers__c to true on those instances
Set the Active__c checkbox to true on every Trigger_Handler_Bypass__mdt record

**Granular bypasses:**

**Scenario 4:** disable specific non-managed triggers for all users
Set the Control_Flag__c.Disable_Triggers__c organization default to false
Set the Active__c checkbox to true on specific Trigger_Handler_Bypass__mdt records

**Scenario 5:** disable specific non-managed triggers for specific profile(s):
Set the Control_Flag__c.Disable_Triggers__c organization default to false
Create a Control_Flag__c instance for the desired profile(s)
Set Disable_Triggers__c to true on those instances
Set the Active__c checkbox to true on specific Trigger_Handler_Bypass__mdt records

**Scenario 6:** disable specific non-managed triggers for specific users(s):
Set the Control_Flag__c.Disable_Triggers__c organization default to false
Create a Control_Flag__c instance for the desired user(s)
Set Disable_Triggers__c to true on those instances
Set the Active__c checkbox to true on specific Trigger_Handler_Bypass__mdt records

**Deploy to Salesforce Org:**

<a href="https://githubsfdeploy.herokuapp.com">
  <img src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png" alt="Deploy to Salesforce" />
</a>

## Usage

To create a trigger handler, you simply need to create a class that inherits from **TriggerHandler.cls**. Here is an example for creating an Opportunity trigger handler.

```java
public class OpportunityTriggerHandler extends TriggerHandler {
```

In your trigger handler, to add logic to any of the trigger contexts, you only need to override them in your trigger handler. Here is how we would add logic to a `beforeUpdate` trigger.

```java
public class OpportunityTriggerHandler extends TriggerHandler {

  /* Optional Constructor - better performance */
  public OpportunityTriggerHandler(){
    super('OpportunityTriggerHandler');
  }
  
  public override void beforeUpdate() {
    for(Opportunity o : (List<Opportunity>) Trigger.new) {
      // do something
    }
  }

  // add overrides for other contexts

}
```

**Note:** When referencing the Trigger statics within a class, SObjects are returned versus SObject subclasses like Opportunity, Account, etc. This means that you must cast when you reference them in your trigger handler. You could do this in your constructor if you wanted. 

```java
public class OpportunityTriggerHandler extends TriggerHandler {
  
  /* Optional Constructor - better performance */
  public OpportunityTriggerHandler(){
    super('OpportunityTriggerHandler');
  }
  
  private Map<Id, Opportunity> newOppMap;

  public OpportunityTriggerHandler() {
    this.newOppMap = (Map<Id, Opportunity>) Trigger.newMap;
  }
  
  public override void afterUpdate() {
    //
  }

}
```

To use the trigger handler, you only need to construct an instance of your trigger handler within the trigger handler itself and call the `run()` method. Here is an example of the Opportunity trigger.

```java
trigger OpportunityTrigger on Opportunity (before insert, before update) {
  new OpportunityTriggerHandler().run();
}
```

## Cool Stuff

### Max Loop Count

To prevent recursion, you can set a max loop count for Trigger Handler. If this max is exceeded, and exception will be thrown. A great use case is when you want to ensure that your trigger runs once and only once within a single execution. Example:

```java
public class OpportunityTriggerHandler extends TriggerHandler {
  
  /* Optional Constructor - better performance */
  public OpportunityTriggerHandler(){
    super('OpportunityTriggerHandler');
  }
  
  public OpportunityTriggerHandler() {
    this.setMaxLoopCount(1);
  }
  
  public override void afterUpdate() {
    List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE Id IN :Trigger.newMap.keySet()];
    update opps; // this will throw after this update
  }

}
```

### Bypass API

What if you want to tell other trigger handlers to halt execution? That's easy with the bypass api:

```java
public class OpportunityTriggerHandler extends TriggerHandler {
  
  /* Optional Constructor - better performance */
  public OpportunityTriggerHandler(){
    super('OpportunityTriggerHandler');
  }
  
  public override void afterUpdate() {
    List<Opportunity> opps = [SELECT Id, AccountId FROM Opportunity WHERE Id IN :Trigger.newMap.keySet()];
    
    Account acc = [SELECT Id, Name FROM Account WHERE Id = :opps.get(0).AccountId];

    TriggerHandler.bypass('AccountTriggerHandler');

    acc.Name = 'No Trigger';
    update acc; // won't invoke the AccountTriggerHandler

    TriggerHandler.clearBypass('AccountTriggerHandler');

    acc.Name = 'With Trigger';
    update acc; // will invoke the AccountTriggerHandler

  }

}
```

If you need to check if a handler is bypassed, use the `isBypassed` method:

```java
if (TriggerHandler.isBypassed('AccountTriggerHandler')) {
  // ... do something if the Account trigger handler is bypassed!
}
```

If you want to clear all bypasses for the transaction, simple use the `clearAllBypasses` method, as in:

```java
// ... done with bypasses!

TriggerHandler.clearAllBypasses();

// ... now handlers won't be ignored!
```

Salesforce Admins (non-devs) can bypass trigger handlers org-wide, or granularily based on profile/user, via the **Control_Flags** custom setting and **Trigger_Handler_Bypass__mdt** custom metadata type:

![control flags v2](https://user-images.githubusercontent.com/124932501/230442307-f2849814-c7a9-41b9-8f7d-aceef41f2a5e.png)

----------------------------

![trigger handler bypasses v2](https://user-images.githubusercontent.com/124932501/230442632-3d420b67-ca67-4238-8b90-9049b606278e.png)

----------------------------

## Overridable Methods

Here are all of the methods that you can override. All of the context possibilities are supported.

* `beforeInsert()`
* `beforeUpdate()`
* `beforeDelete()`
* `afterInsert()`
* `afterUpdate()`
* `afterDelete()`
* `afterUndelete()`
