# Score API

POST https://score.autofinanzas-sandbox.com/v1/score
Auth: header x-api-key

Request
{ "opportunityId": "006...", "amount": 30000, "segment": "Fleet" }

Response 200
{ "score": 712, "status": "APPROVED" | "REVIEW" | "REJECTED" }

Errores: 400 (payload inválido), 429 (rate limit), 500 (error interno)
Límite: 1 oportunidad por request.
