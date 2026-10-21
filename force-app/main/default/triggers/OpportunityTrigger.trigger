trigger OpportunityTrigger on Opportunity (before update) {
    OpportunityTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
}
