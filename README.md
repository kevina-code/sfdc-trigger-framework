# ApexUtilities
Useful Apex utility methods to save time and improve efficiency.

These methods can be found in 2 places in this repo: 
1.  The [ApexUtils.cls](https://github.com/kevina-code/apexutilities/blob/main/ApexUtils) file
2.  Individually listed in the [ApexUtils Methods](https://github.com/kevina-code/apexutilities/tree/main/ApexUtils%20Methods) directory 

Usage:
First, deploy [ApexUtils.cls](https://github.com/kevina-code/ApexUtilities/blob/main/ApexUtils) and [ApexUtilsTest.cls](https://github.com/kevina-code/ApexUtilities/blob/main/ApexUtilsTest)

**[Scheduler()](https://github.com/kevina-code/ApexUtilities/blob/main/ApexUtils%20Methods/Scheduler)** usage:
1. Example Invocation:
```java
// queue a schedulable class called MySchedulableApexClassName to run 1.5 hours from now:
ApexUtils.Scheduler scheduler = new ApexUtils.Scheduler(
  'myJob', 'MySchedulableApexClassName').addHours(1).addMinutes(30).run();
```

**[getAllFieldsForSObjAsStr()](https://github.com/kevina-code/ApexUtilities/blob/main/ApexUtils%20Methods/getAllFieldsForSObjAsStr)** usage:
1. Example Invocation::
```java
// query all fields on 10 Accounts:
List<Account> accounts = Database.query('SELECT ' + ApexUtils.getAllFieldsForSObjAsStr('Account') + ' FROM Account LIMIT 10');
```

**[getEnvironmentName()](https://github.com/kevina-code/ApexUtilities/blob/main/ApexUtils%20Methods/getEnvironmentName)** usage:
1. Example Invocation:
```java
// get the environment name of the org. For example, if org URL is 'https://xyzcompany.my.salesforce.com', this will return 'xyzcompany'
String environmentName = ApexUtils.getEnvironmentName(); 
```

**[getFieldSetFieldAPINames()](https://github.com/kevina-code/ApexUtilities/blob/main/ApexUtils%20Methods/getFieldSetFieldAPINames)** usage:
1. Example Invocation:
```
// get the field API Names for fields in a particular field set:
List<String> acctFieldSetFieldApiNames = ApexUtils.getFieldSetFieldAPINames('Account_Field_Set_1', 'Account'); 
```

**[getFilesOnRecord()](https://github.com/kevina-code/ApexUtilities/blob/main/ApexUtils%20Methods/getFilesOnRecord)** usage:
1. Example Invocation:

```java
// example data:
Account account = [SELECT Id FROM Account LIMIT 1];

// get .csv files on an Account record
List<ContentVersion> acctCsvFiles = ApexUtils.getFilesOnRecord(account, 'csv');
```

**[groupBy()](https://github.com/kevina-code/ApexUtilities/blob/main/ApexUtils%20Methods/groupBy)** usage:
1. Example Invocation:
```java
// example data:
List<Account> accounts = [SELECT Id, ParentId, Name FROM Account LIMIT 10];

// group accounts by ParentId:
Map<String, List<Account>> acctsByParentId = ApexUtils.groupBy(accounts, 'ParentId');
```

**[mapSorter()](https://github.com/kevina-code/ApexUtilities/blob/main/ApexUtils%20Methods/mapSorter)** usage:
1. Example Invocation:
```java
// example data:
Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Name FROM Account LIMIT 10]);
Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id, Name FROM Contact LIMIT 10]);
Map<Id, Contact> accountMap2 = new Map<Id, Contact>([SELECT Id, Name FROM Contact LIMIT 10]);

Map<Id, SObject> acctsAndContactsMap = new Map<Id, SObject>();
acctsAndContactsMap.putAll(accountMap);
acctsAndContactsMap.putAll(contactMap);
acctsAndContactsMap.putAll(accountMap2);

// sort SObject map by Id, essentially sorting by object api name; useful for when performing DML on an SObject list with multiple object types:
Map<Id, SObject> sortedMap = ApexUtils.mapSorter(acctsAndContactsMap);
```

**[mapSorterByNumOfChildren()](https://github.com/kevina-code/ApexUtilities/blob/main/ApexUtils%20Methods/mapSorterByNumOfChildren)** usage:
1. Example Invocation:
```java
// example data:
Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Name FROM Account LIMIT 10]);
Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id, Name FROM Contact LIMIT 7]);
Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, Name FROM Opportunity LIMIT 13]);

Map<Id, SObject> recordsMap = new Map<Id, SObject>();
recordsMap.putAll(accountMap);
recordsMap.putAll(contactMap);
recordsMap.putAll(oppMap);

// sort SObject map by SObject type's number of records ascending (instead of 10, 7, 13, the order will be 7, 10, 13)
Map<Id, SObject> sortedMap = ApexUtils.mapSorterByNumOfChildren(recordsMap);
```

**[parseFieldPathForSObject()](https://github.com/kevina-code/ApexUtilities/blob/main/ApexUtils%20Methods/parseFieldPathForSObject)** usage:
1. Example Invocation:
```java
// example data:
Contact contact = [SELECT Id, Name, Account.Name FROM Contact LIMIT 1];

// dynamically get the field value as an Object for a multi-dimensional path:
Object fieldValueObj = ApexUtils.parseFieldPathForSObject(contact, 'Account.Name');
```

**[readFieldSet()](https://github.com/kevina-code/ApexUtilities/blob/main/ApexUtils%20Methods/readFieldSet)** usage:
1. Example Invocation:
```java
// read a field set and cast it into a List<Schema.FieldSetMember>
List<Schema.FieldSetMember> fieldSet = ApexUtils.readFieldSet('Account_Field_Set_1', 'Account');
```

**[findChangedRecs()](https://github.com/kevina-code/ApexUtilities/blob/main/ApexUtils%20Methods/findChangedRecs)** usage:
1. Example Invocation:
```java
// in an Account trigger context, get accounts where Name has changed:
List<SObject> changedAccounts = ApexUtils.findChangedRecs(
  accounts,
  accountMap,
  Schema.Account.Name
);
```

**[findChangedRecsWithMatchingVal()](https://github.com/kevina-code/ApexUtilities/blob/main/ApexUtils%20Methods/findChangedRecsWithMatchingVal)** usage:
1. Example Invocation:
```java
// in an Account trigger context, get accounts where Name has changed to 'ABC Corp':
List<SObject> changedAccounts = ApexUtils.findChangedRecsWithMatchingVal(
  accounts,
  accountMap,
  Schema.Account.Name,
  'ABC Corp'
);
```

**[findRecsWithMatchingValue()](https://github.com/kevina-code/ApexUtilities/blob/main/ApexUtils%20Methods/findRecsWithMatchingValue)** usage:
1. Example Invocation:
```java
// given a list of Accounts, find those whose Type = 'Business':
List<SObject> accountsToCheck = ApexUtils.findRecsWithMatchingValue(
  accounts,
  Schema.Account.Type,
  'Business'
);
```
