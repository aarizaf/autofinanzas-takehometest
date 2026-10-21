// Cliente HTTP del servicio de scoring. Solo habla con el API, no conoce Opportunity.
// La URL y la x-api-key viven en el Custom Metadata Score_Api_Config__mdt (registro 'Default'), no en el código.
public with sharing class ScoreApiClient {

    public class Result {
        public Integer score;
        public String status;
    }

    // Devuelve null si el API falla (429, 500, 400, timeout); el llamador decide qué hacer.
    public static Result score(Id opportunityId, Decimal amount, String segment) {
        // getInstance no consume queries SOQL
        Score_Api_Config__mdt config = Score_Api_Config__mdt.getInstance('Default');

        HttpRequest req = new HttpRequest();
        req.setEndpoint(config.Base_Url__c + '/v1/score');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('x-api-key', config.Api_Key__c);
        req.setBody(JSON.serialize(new Map<String, Object>{
            'opportunityId' => opportunityId,
            'amount' => amount,
            'segment' => segment
        }));

        HttpResponse res;
        try {
            res = new Http().send(req);
        } catch (CalloutException e) {
            return null;
        }
        return res.getStatusCode() == 200 ? (Result) JSON.deserialize(res.getBody(), Result.class) : null;
    }
}
