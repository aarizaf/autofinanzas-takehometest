@isTest
private class DiscountStrategyTest {

    private static Opportunity opp(Decimal amount, Decimal vehicles) {
        return new Opportunity(Amount = amount, Vehicle_Count__c = vehicles);
    }

    @isTest
    static void retail_discountOnlyAboveThreshold() {
        RetailDiscount s = new RetailDiscount();
        System.assertEquals(2, s.calculate(opp(20001, null)));
        System.assertEquals(0, s.calculate(opp(20000, null)));
        System.assertEquals(0, s.calculate(opp(null, null)), 'Sin monto no hay descuento');
    }

    @isTest
    static void corporate_isAlwaysFive() {
        System.assertEquals(5, new CorporateDiscount().calculate(opp(1, null)));
    }

    @isTest
    static void fleet_threePercentPerFullBlockOfFive() {
        FleetDiscount s = new FleetDiscount();
        System.assertEquals(0, s.calculate(opp(1, 4)), 'Menos de 5 vehículos');
        System.assertEquals(3, s.calculate(opp(1, 5)));
        System.assertEquals(3, s.calculate(opp(1, 9)), 'Solo cuentan bloques completos');
        System.assertEquals(12, s.calculate(opp(1, 20)));
        System.assertEquals(12, s.calculate(opp(1, 100)), 'Tope de 12%');
        System.assertEquals(0, s.calculate(opp(1, null)), 'Sin vehículos no hay descuento');
    }

    @isTest
    static void domain_unknownSegment_leavesDiscountUntouched() {
        // En memoria: el picklist es restringido y no permite insertar 'Government'
        Id fakeAccountId = '001000000000001AAA';
        Account acc = new Account(Id = fakeAccountId, Customer_Segment__c = 'Government');
        Opportunity o = new Opportunity(AccountId = fakeAccountId, Amount = 50000);

        OpportunityDomain.applyDiscount(
            new List<Opportunity>{ o },
            new Map<Id, Account>{ fakeAccountId => acc }
        );

        System.assertEquals(null, o.Discount__c, 'Segmento sin clase XxxDiscount no recibe descuento');
    }
}
