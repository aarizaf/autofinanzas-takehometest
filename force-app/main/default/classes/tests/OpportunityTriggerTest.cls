@isTest
private class OpportunityTriggerTest {

    private static Account createAccount(String segment) {
        Account a = new Account(Name = 'Test ' + segment, Customer_Segment__c = segment);
        insert a;
        return a;
    }

    private static List<Opportunity> createOpps(Id accountId, Integer count, Decimal amount) {
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < count; i++) {
            opps.add(new Opportunity(
                Name = 'Opp ' + i, AccountId = accountId, StageName = 'Prospecting',
                CloseDate = Date.today(), Amount = amount
            ));
        }
        insert opps;
        return opps;
    }

    private static List<Opportunity> reload(List<Opportunity> opps) {
        return [SELECT Id, Discount__c, Description, Credit_Status__c FROM Opportunity WHERE Id IN :opps];
    }

    private static void moveToCreditReview(List<Opportunity> opps) {
        Test.setMock(HttpCalloutMock.class, ScoreApiMock.approved());
        for (Opportunity o : opps) {
            o.StageName = 'Credit Review';
        }
        update opps;
    }

    @isTest
    static void retailOverThreshold_getsTwoPercentAndDescription() {
        List<Opportunity> opps = createOpps(createAccount('Retail').Id, 1, 30000);

        moveToCreditReview(opps);

        Opportunity result = reload(opps)[0];
        System.assertEquals(2, result.Discount__c, 'Retail con monto > 20000 recibe 2%');
        System.assertEquals('Sent to review on ' + System.today(), result.Description);
    }

    @isTest
    static void retailAtThreshold_getsZeroButIsMarked() {
        List<Opportunity> opps = createOpps(createAccount('Retail').Id, 1, 20000);

        moveToCreditReview(opps);

        Opportunity result = reload(opps)[0];
        System.assertEquals(0, result.Discount__c, 'Monto igual al umbral no califica');
        System.assertNotEquals(null, result.Description);
    }

    @isTest
    static void corporate_getsFivePercent() {
        List<Opportunity> opps = createOpps(createAccount('Corporate').Id, 1, 1000);

        moveToCreditReview(opps);

        System.assertEquals(5, reload(opps)[0].Discount__c);
    }

    @isTest
    static void fleet_getsThreePercentPerFiveVehicles() {
        List<Opportunity> opps = createOpps(createAccount('Fleet').Id, 1, 1000);
        opps[0].Vehicle_Count__c = 10;
        update opps;

        moveToCreditReview(opps);

        System.assertEquals(6, reload(opps)[0].Discount__c, '10 vehículos = 2 bloques = 6%');
    }

    @isTest
    static void accountWithoutSegment_noDiscountButIsMarked() {
        List<Opportunity> opps = createOpps(createAccount(null).Id, 1, 30000);

        moveToCreditReview(opps);

        Opportunity result = reload(opps)[0];
        System.assertEquals(null, result.Discount__c);
        System.assertNotEquals(null, result.Description);
    }

    @isTest
    static void withoutAccount_doesNotFail() {
        List<Opportunity> opps = createOpps(null, 1, 30000);

        moveToCreditReview(opps);

        Opportunity result = reload(opps)[0];
        System.assertEquals(null, result.Discount__c);
        System.assertNotEquals(null, result.Description);
    }

    @isTest
    static void alreadyInCreditReview_isNotReprocessed() {
        List<Opportunity> opps = createOpps(createAccount('Retail').Id, 1, 30000);
        moveToCreditReview(opps);

        // Un update posterior sin cambio de etapa no debe volver a marcar
        Opportunity loaded = reload(opps)[0];
        loaded.Description = 'edited manually';
        update loaded;

        System.assertEquals('edited manually', reload(opps)[0].Description);
    }

    @isTest
    static void bulk200_usesOneQueryForAccountsAndProcessesAll() {
        List<Opportunity> opps = createOpps(createAccount('Corporate').Id, 200, 1000);
        for (Opportunity o : opps) {
            o.StageName = 'Credit Review';
        }
        Test.setMock(HttpCalloutMock.class, ScoreApiMock.approved());

        Test.startTest();
        update opps;
        System.assertEquals(2, Limits.getQueueableJobs(), '200 oportunidades = 2 jobs de 100, no 200 jobs');
        Test.stopTest();

        for (Opportunity o : reload(opps)) {
            System.assertEquals(5, o.Discount__c);
            System.assertNotEquals(null, o.Description);
            System.assertEquals('Approved', o.Credit_Status__c, 'Los 2 jobs procesaron todo el lote');
        }
    }
}
