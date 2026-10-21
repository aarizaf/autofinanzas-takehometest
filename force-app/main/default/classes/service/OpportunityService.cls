// Service: orquesta el caso de uso. Pide datos al Selector y reglas al Domain.
public with sharing class OpportunityService {

    public static void processCreditReview(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        List<Opportunity> entering = OpportunityDomain.enteringCreditReview(newOpps, oldMap);
        if (entering.isEmpty()) {
            return;
        }

        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : entering) {
            accountIds.add(opp.AccountId);
        }

        Map<Id, Account> accounts = AccountSelector.byIds(accountIds);
        OpportunityDomain.applyDiscount(entering, accounts);
        OpportunityDomain.markForReview(entering);

        // Un job por cada grupo de 100 (límite de callouts por transacción)
        List<CreditScoreQueueable.ScoreRequest> batch = new List<CreditScoreQueueable.ScoreRequest>();
        for (Opportunity opp : entering) {
            Account acc = accounts.get(opp.AccountId);
            batch.add(new CreditScoreQueueable.ScoreRequest(
                opp.Id, opp.Amount, acc == null ? null : acc.Customer_Segment__c
            ));
            if (batch.size() == CreditScoreQueueable.maxCallouts) {
                System.enqueueJob(new CreditScoreQueueable(batch));
                batch = new List<CreditScoreQueueable.ScoreRequest>();
            }
        }
        if (!batch.isEmpty()) {
            System.enqueueJob(new CreditScoreQueueable(batch));
        }
    }
}
