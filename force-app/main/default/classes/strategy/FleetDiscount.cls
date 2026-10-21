// Fleet: 3% por cada 5 vehículos completos, máximo 12%.
public with sharing class FleetDiscount implements DiscountStrategy {

    public Decimal calculate(Opportunity opp) {
        if (opp.Vehicle_Count__c == null) {
            return 0;
        }
        Integer blocksOfFive = (Integer) Math.floor(opp.Vehicle_Count__c / 5);
        return Math.min(12, blocksOfFive * 3);
    }
}
