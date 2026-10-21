// Contrato: cada segmento implementa su propia regla de descuento.
public interface DiscountStrategy {
    Decimal calculate(Opportunity opp);
}
