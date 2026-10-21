// Consulta el score de un grupo de oportunidades que entraron a Credit Review.
// Es asíncrono porque un trigger no puede hacer callouts, y el API acepta 1 oportunidad por request.
// Límite de Salesforce: 100 callouts por transacción, por eso el Service manda grupos de máximo 100.
public with sharing class CreditScoreQueueable implements Queueable, Database.AllowsCallouts {

    @TestVisible public static Integer maxCallouts = 100;

    public class ScoreRequest {
        public Id opportunityId;
        public Decimal amount;
        public String segment;

        public ScoreRequest(Id opportunityId, Decimal amount, String segment) {
            this.opportunityId = opportunityId;
            this.amount = amount;
            this.segment = segment;
        }
    }

    private final List<ScoreRequest> requests;

    public CreditScoreQueueable(List<ScoreRequest> requests) {
        this.requests = requests;
    }

    public void execute(QueueableContext context) {
        List<Opportunity> toUpdate = new List<Opportunity>();
        for (ScoreRequest r : requests) {
            ScoreApiClient.Result result = ScoreApiClient.score(r.opportunityId, r.amount, r.segment);
            if (result != null) {
                toUpdate.add(new Opportunity(
                    Id = r.opportunityId,
                    Credit_Score__c = result.score,
                    // APPROVED -> Approved (valor del picklist)
                    Credit_Status__c = result.status.substring(0, 1).toUpperCase()
                        + result.status.substring(1).toLowerCase()
                ));
            }
        }
        update toUpdate; // un solo DML, después de todos los callouts
    }
}
