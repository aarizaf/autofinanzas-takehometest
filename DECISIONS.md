# DECISIONS

## Qué patrón usé, dónde y qué principio resuelve

| Patrón | Dónde | Principio |
|---|---|---|
| Capas: Handler → Service → Domain → Selector | `OpportunityTriggerHandler`, `OpportunityService`, `OpportunityDomain`, `AccountSelector` | **S** (responsabilidad única). El Handler solo enruta, el Service orquesta, el Domain tiene las reglas (sin SOQL ni DML) y el Selector concentra el SOQL. |
| Strategy | `DiscountStrategy` + `RetailDiscount`, `CorporateDiscount`, `FleetDiscount` | **O** (abierto/cerrado). Un segmento nuevo es una clase nueva `XxxDiscount` y su valor en el picklist; no se edita ninguna clase existente. |
| Interfaz de un solo método | `DiscountStrategy.calculate(opp)` | **D** e **I**. El Domain depende de la interfaz, no de clases concretas, y las estrategias no implementan nada que no usen. |
| Cliente HTTP separado | `ScoreApiClient` (HTTP) y `CreditScoreQueueable` (qué se guarda) | **S**. El cliente no conoce Opportunity; el Queueable no conoce HTTP. |
| Queueable | `CreditScoreQueueable` | Un trigger no puede hacer callouts y el API acepta 1 oportunidad por request. |
| Permission Set solo de campos | `Credit_Analyst_Access` | Mínimo privilegio. El perfil ya da los objetos; el Permission Set agrega solo los 5 campos que faltan (detalle en `ASSUMPTIONS.md`). |

## Dónde decidí NO aplicar un principio o patrón

- **Sin inyección de dependencias ni interfaces para Service y Selector (D).** Hay una sola query y una sola implementación. Una interfaz más un mock costarían más código que lo que protegen. Los tests pasan por el trigger y mockean solo el HTTP, que es el único límite externo real.
- **Sin Factory ni registro en Custom Metadata para las estrategias.** Lo construí y lo retiré. La estrategia se resuelve con `segmento + 'Discount'` y `Type.forName`. Es menos código y menos piezas, a costa de una convención implícita: si una clase no sigue el nombre, falla en silencio (sin descuento).
- **Sin encadenar Queueables.** El Service reparte los requests en grupos de 100 y encola un job por grupo. Cada job tiene su propio límite de 100 callouts, y además Salesforce no permite ejecutar jobs encadenados en tests.
- **API key en Custom Metadata (`Score_Api_Config__mdt`)**, no en una Named Credential. Es más simple, pero el valor no está cifrado. En producción usaría Named Credential con External Credential.
- **Sin framework de triggers.** El trigger solo escucha `before update`, igual que el original; un framework con registro de eventos sería exceso para un caso.
- **El analista tiene edición sobre `Credit_Score__c` y `Credit_Status__c`.** Es necesario porque el job corre con su usuario y escribe esos campos, pero permite cambiar el score a mano. Lo acepté por simplicidad; en producción usaría un usuario de integración para el job o una validación que impida la edición manual.
- **`with sharing`** en todas las clases (el original era `without sharing` sin justificación).
