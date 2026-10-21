// Corporate: 5% fijo.
public with sharing class CorporateDiscount implements DiscountStrategy {

    public Decimal calculate(Opportunity opp) {
        return 5;
    }
}
