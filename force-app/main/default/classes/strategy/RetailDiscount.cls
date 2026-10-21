// Retail: 2% si el monto es mayor a 20,000.
public with sharing class RetailDiscount implements DiscountStrategy {

    public Decimal calculate(Opportunity opp) {
        return opp.Amount != null && opp.Amount > 20000 ? 2 : 0;
    }
}
