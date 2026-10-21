// Simula el servicio de scoring. Cuenta las llamadas para poder comprobarlas en los tests.
@isTest
public class ScoreApiMock implements HttpCalloutMock {

    public static Integer calls = 0;
    private final Integer statusCode;
    private final String body;

    public ScoreApiMock(Integer statusCode, String body) {
        this.statusCode = statusCode;
        this.body = body;
    }

    public static ScoreApiMock approved() {
        return new ScoreApiMock(200, '{"score": 712, "status": "APPROVED"}');
    }

    public HttpResponse respond(HttpRequest req) {
        calls++;
        System.assertEquals('POST', req.getMethod());
        System.assert(req.getEndpoint().endsWith('/v1/score'));
        if (statusCode == 0) {
            throw new CalloutException('timeout');
        }
        HttpResponse res = new HttpResponse();
        res.setStatusCode(statusCode);
        res.setBody(body);
        return res;
    }
}
