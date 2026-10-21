// Domain: reglas de negocio sobre Opportunity. Sin SOQL ni DML.
public with sharing class OpportunityDomain {

    // Oportunidades que acaban de entrar a Credit Review
    public static List<Opportunity> enteringCreditReview(List<Opportunity> opps, Map<Id, Opportunity> oldMap) {
        List<Opportunity> result = new List<Opportunity>();
        for (Opportunity opp : opps) {
            Boolean changedToReview = opp.StageName == 'Credit Review'
                && oldMap.get(opp.Id).StageName != 'Credit Review';
            if (changedToReview) {
                result.add(opp);
            }
        }
        return result;
    }

    public static void applyDiscount(List<Opportunity> opps, Map<Id, Account> accounts) {
        for (Opportunity opp : opps) {
            Account acc = accounts.get(opp.AccountId);
            if (acc == null) {
                continue;
            }
            DiscountStrategy strategy = strategyFor(acc.Customer_Segment__c);
            if (strategy != null) {
                opp.Discount__c = strategy.calculate(opp);
            }
        }
    }

    // Convención: segmento 'Retail' -> clase 'RetailDiscount'.
    // Un segmento nuevo solo necesita su clase XxxDiscount; no se edita nada existente.
    private static DiscountStrategy strategyFor(String segment) {
        if (segment == null) {
            return null;
        }
        Type strategyType = Type.forName(segment + 'Discount');
        return strategyType == null ? null : (DiscountStrategy) strategyType.newInstance();
    }

    public static void markForReview(List<Opportunity> opps) {
        for (Opportunity opp : opps) {
            opp.Description = 'Sent to review on ' + System.today();
            opp.Credit_Status__c = 'Pending'; // hasta que responda el servicio de scoring
        }
    }
}
