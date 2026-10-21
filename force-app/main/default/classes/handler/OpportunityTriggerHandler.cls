// Handler: solo enruta el evento del trigger al Service.
public with sharing class OpportunityTriggerHandler {

    public static void beforeUpdate(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        OpportunityService.processCreditReview(newOpps, oldMap);
    }
}
