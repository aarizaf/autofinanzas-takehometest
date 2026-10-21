@isTest
private class CreditScoreTest {

    private static List<Opportunity> createOpps(Integer count) {
        Account a = new Account(Name = 'Test', Customer_Segment__c = 'Retail');
        insert a;
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < count; i++) {
            opps.add(new Opportunity(
                Name = 'Opp ' + i, AccountId = a.Id, StageName = 'Prospecting',
                CloseDate = Date.today(), Amount = 30000
            ));
        }
        insert opps;
        return opps;
    }

    private static void moveToCreditReview(List<Opportunity> opps) {
        for (Opportunity o : opps) {
            o.StageName = 'Credit Review';
        }
        Test.startTest();
        update opps;
        Test.stopTest();
    }

    private static List<Opportunity> reload(List<Opportunity> opps) {
        return [SELECT Id, Credit_Score__c, Credit_Status__c FROM Opportunity WHERE Id IN :opps];
    }

    @isTest
    static void approvedResponse_savesScoreAndStatus() {
        ScoreApiMock.calls = 0;
        Test.setMock(HttpCalloutMock.class, ScoreApiMock.approved());
        List<Opportunity> opps = createOpps(3);

        moveToCreditReview(opps);

        for (Opportunity o : reload(opps)) {
            System.assertEquals(712, o.Credit_Score__c);
            System.assertEquals('Approved', o.Credit_Status__c);
        }
        System.assertEquals(3, ScoreApiMock.calls, 'Un callout por oportunidad');
    }

    @isTest
    static void rateLimitResponse_leavesStatusPending() {
        Test.setMock(HttpCalloutMock.class, new ScoreApiMock(429, '{}'));
        List<Opportunity> opps = createOpps(1);

        moveToCreditReview(opps);

        Opportunity result = reload(opps)[0];
        System.assertEquals(null, result.Credit_Score__c, 'Sin respuesta válida no se inventa un score');
        System.assertEquals('Pending', result.Credit_Status__c);
    }

    @isTest
    static void timeout_leavesStatusPending() {
        Test.setMock(HttpCalloutMock.class, new ScoreApiMock(0, ''));
        List<Opportunity> opps = createOpps(1);

        moveToCreditReview(opps);

        System.assertEquals('Pending', reload(opps)[0].Credit_Status__c);
    }

    @isTest
    static void moreThanMaxCallouts_isSplitIntoGroups() {
        Test.setMock(HttpCalloutMock.class, ScoreApiMock.approved());
        CreditScoreQueueable.maxCallouts = 2;
        List<Opportunity> opps = createOpps(5);
        for (Opportunity o : opps) {
            o.StageName = 'Credit Review';
        }

        Test.startTest();
        update opps;
        Integer jobs = Limits.getQueueableJobs();
        Test.stopTest();

        System.assertEquals(3, jobs, '5 oportunidades en grupos de 2 = 3 jobs (2 + 2 + 1)');
        for (Opportunity o : reload(opps)) {
            System.assertEquals('Approved', o.Credit_Status__c);
        }
    }

    @isTest
    static void alreadyInCreditReview_doesNotEnqueueAnotherJob() {
        Test.setMock(HttpCalloutMock.class, ScoreApiMock.approved());
        List<Opportunity> opps = createOpps(1);
        moveToCreditReview(opps);
        Integer jobsBefore = Limits.getQueueableJobs();

        opps[0].Description = 'edited';
        update opps;

        System.assertEquals(jobsBefore, Limits.getQueueableJobs(), 'Sin cambio de etapa no se vuelve a consultar el API');
    }
}
