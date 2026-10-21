@isTest
private class CreditAnalystPermissionTest {

    private static User createAnalyst(Boolean withPermissionSet) {
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Analista de Crédito'].Id;
        User analyst = new User(
            LastName = 'Analista', Alias = 'analis', Email = 'afperez@test.com',
            Username = 'analista' + System.currentTimeMillis() + '@test.com',
            ProfileId = profileId, TimeZoneSidKey = 'America/Bogota', LocaleSidKey = 'es_CO',
            EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US'
        );
        // Los objetos de setup (User, asignación) se crean en un contexto aparte del resto de datos
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert analyst;
            if (withPermissionSet) {
                insert new PermissionSetAssignment(
                    AssigneeId = analyst.Id,
                    PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Credit_Analyst_Access'].Id
                );
            }
        }
        return analyst;
    }

    // Oportunidad en Prospecting, de un cliente Corporate, propiedad del analista
    private static Opportunity createOpportunityOwnedBy(User analyst) {
        Account acc = new Account(Name = 'Test', Customer_Segment__c = 'Corporate');
        insert acc;
        Opportunity opp = new Opportunity(
            Name = 'Opp', AccountId = acc.Id, StageName = 'Prospecting', CloseDate = Date.today(),
            Amount = 1000, OwnerId = analyst.Id
        );
        insert opp;
        return opp;
    }

    private static void moveToCreditReviewAs(User analyst, Opportunity opp) {
        Test.setMock(HttpCalloutMock.class, ScoreApiMock.approved());
        Test.startTest();
        System.runAs(analyst) {
            // El analista solo cambia la etapa, no reenvía el resto de campos
            update new Opportunity(Id = opp.Id, StageName = 'Credit Review');
        }
        Test.stopTest();
    }

    @isTest
    static void analystWithPermissionSet_seesDiscountAndScore() {
        User analyst = createAnalyst(true);
        Opportunity opp = createOpportunityOwnedBy(analyst);

        moveToCreditReviewAs(analyst, opp);

        System.runAs(analyst) {
            // WITH USER_MODE hace que la consulta respete los permisos de campo del usuario
            Opportunity result = [
                SELECT Discount__c, Credit_Score__c, Credit_Status__c, Vehicle_Count__c
                FROM Opportunity WHERE Id = :opp.Id WITH USER_MODE
            ];
            System.assertEquals(5, result.Discount__c);
            System.assertEquals(712, result.Credit_Score__c);
            System.assertEquals('Approved', result.Credit_Status__c);

            Account acc = [SELECT Customer_Segment__c FROM Account WHERE Id = :opp.AccountId WITH USER_MODE];
            System.assertEquals('Corporate', acc.Customer_Segment__c);
        }
    }

    @isTest
    static void analystWithoutPermissionSet_cannotMoveToCreditReview() {
        User analyst = createAnalyst(false);
        Opportunity opp = createOpportunityOwnedBy(analyst);

        try {
            moveToCreditReviewAs(analyst, opp);
            System.assert(false, 'Sin el Permission Set el trigger no puede leer Customer_Segment__c');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Customer_Segment__c'), e.getMessage());
        }
        System.assertEquals('Prospecting', [SELECT StageName FROM Opportunity WHERE Id = :opp.Id].StageName);
    }
}
