// Selector: único lugar donde se consulta Account.
public with sharing class AccountSelector {

    public static Map<Id, Account> byIds(Set<Id> ids) {
        return new Map<Id, Account>([SELECT Id, Customer_Segment__c FROM Account WHERE Id IN :ids]);
    }
}
