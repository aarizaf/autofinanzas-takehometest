# ASSUMPTIONS

## Cómo interpreté el requerimiento

1. **"Entrar a Credit Review"** es el cambio de cualquier otra etapa a `Credit Review`. Un update posterior sin cambio de etapa no vuelve a calcular el descuento, ni a marcar, ni a llamar al API.
2. **Solo `before update`.** El original no escuchaba `insert` y el enunciado pide mantener el comportamiento, así que una oportunidad creada directamente en `Credit Review` no se procesa.
3. **La regla antigua (`Account.Type = 'Customer - Direct'`, 2 % si monto > 20,000) queda reemplazada** por el segmento. Retail ya cubre esa misma regla.
4. **Descuento por segmento:**
   - Retail: 2 si `Amount > 20000` (exactamente 20000 no califica); si no califica se guarda 0.
   - Corporate: 5 fijo.
   - Fleet: 3 por cada bloque *completo* de 5 vehículos (9 vehículos = 3), máximo 12. `Vehicle_Count__c` null = 0.
   - Segmento null o sin clase de estrategia: no hay descuento y `Discount__c` no se toca.
5. **`Discount__c` es un campo Percent**: el valor 2 significa 2 %.
6. **El descuento no se limpia** si la oportunidad luego deja de calificar. El enunciado no lo pide.
7. **Oportunidad sin cuenta** (`AccountId` null): se marca para revisión, pero sin descuento y con segmento null hacia el API.

## Scoring

8. La consulta al API es **asíncrona** (Queueable); el resultado no está disponible en la misma transacción.
9. Al entrar a `Credit Review`, `Credit_Status__c` queda en **`Pending`** hasta que responda el API.
10. El `status` del API (`APPROVED`, `REVIEW`, `REJECTED`) se guarda con el formato del picklist (`Approved`, `Review`, `Rejected`).
11. **Si el API falla** (400, 429, 500 o timeout) la oportunidad se queda en `Pending` y sin score. No hay reintentos; es un límite conocido.
12. **Un job por cada 100 oportunidades** (límite de 100 callouts por transacción). Un trigger procesa como máximo 200 registros, es decir 2 jobs; el límite de 50 jobs encolados por transacción no se alcanza en ese caso.
13. La URL y la `x-api-key` están en `Score_Api_Config__mdt` (registro `Default`). El repo trae el valor `REEMPLAZAR_EN_SETUP`; la clave real se escribe en Setup y no se sube al repositorio.

## Bugs encontrados en el código original

| # | Bug | Dónde | Consecuencia | Corrección |
|---|---|---|---|---|
| 1 | SOQL dentro de un `for` | `applyDiscount` | Con 101+ registros: `Too many SOQL queries` | Un solo SOQL con `Set<Id>` en el Selector |
| 2 | DML dentro de un `for` | `markForReview` | Con 151+ registros: `Too many DML statements` | Se asigna el campo en `before update`, sin DML |
| 3 | `[SELECT ...]` asignado a un `Account` | `applyDiscount` | Sin `AccountId` o sin cuenta visible: `QueryException` y falla toda la carga | Búsqueda en un `Map`; `get(null)` devuelve null |
| 4 | Se procesa en cada update mientras la etapa sea `Credit Review` | Ambos métodos | Se recalcula y vuelve a marcar aunque no cambie la etapa | Se compara contra `Trigger.oldMap` |
| 5 | `markForReview` en `after update` con un `update` propio | Trigger/Helper | Dispara de nuevo el trigger (recursión) y gasta DML | Pasó a `before update` |
| 6 | `Amount` null no se validaba | `applyDiscount` | Comparaciones con null | La estrategia valida el monto |
| 7 | `without sharing` sin justificación | `OpportunityHelper` | Ignora la seguridad de registros del usuario | `with sharing` |
| 8 | El test no tenía asserts ni prueba con 200 registros | `OpportunityHelperTest` | Daba cobertura sin comprobar nada | Tests con asserts y casos bulk |

## Parte 3: Permission Set `Credit_Analyst_Access`

El perfil "Analista de Crédito" ya da Account (lectura) y Opportunity (crear, editar, leer), pero deja los 5 campos de esta funcionalidad **sin acceso**. Por eso el Permission Set contiene solo permisos de campo y ningún permiso de objeto.

| Permiso | Acceso | Justificación |
|---|---|---|
| `Account.Customer_Segment__c` | Lectura | El trigger la consulta para calcular el descuento. Sin ella el analista no puede mover una oportunidad a Credit Review: el update falla (probado en `CreditAnalystPermissionTest`). |
| `Opportunity.Discount__c` | Lectura | Ver el descuento calculado. No se edita a mano: lo calcula el trigger. |
| `Opportunity.Vehicle_Count__c` | Lectura | Dato del que depende el descuento Fleet. Asumo que lo captura otro rol; si el analista debe capturarlo, requiere edición. |
| `Opportunity.Credit_Score__c` | Lectura y edición | El job de scoring corre con el usuario que disparó el trigger y escribe este campo. |
| `Opportunity.Credit_Status__c` | Lectura y edición | Igual que el anterior. |

No incluí, a propósito:
- **Acceso a clases Apex:** el trigger y el Queueable que encola no lo requieren.
- **Acceso a `Score_Api_Config__mdt`:** `getInstance` lee el metadata sin permisos.
- **Permisos de objeto:** ya los da el perfil.

Supuestos adicionales:
14. El analista edita oportunidades a las que ya tiene acceso por propiedad o jerarquía; las reglas de compartición quedan fuera del Permission Set.
15. El perfil se desplegó tal como vino en la prueba, que no da acceso a campos estándar como `AccountId` o `Amount`. Por eso en el test el analista solo cambia la etapa.

## Ejecutar los tests en una org nueva

Los campos desplegados por metadatos no dan acceso a nadie, ni siquiera a un administrador, y sin acceso los tests fallan con `No such column`. `Dev_Field_Access` es un Permission Set **solo para desarrollo** que resuelve eso. Se asigna al usuario que ejecuta los tests: `sf org assign permset --name Dev_Field_Access`. No forma parte del acceso del Analista de Crédito.
