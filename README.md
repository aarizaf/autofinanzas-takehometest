### Contexto

AutoFinanzas es una financiera que aprueba créditos vehiculares. Hoy, cuando una `Opportunity` pasa a la etapa `Credit Review`, un trigger calcula un descuento y marca la oportunidad. El código funciona en pruebas manuales, pero falla en cargas masivas y nadie quiere tocarlo.

### Parte 1 — Refactor

1. Refactoriza `OpportunityTrigger` y `OpportunityHelper` hacia una arquitectura en capas: Trigger Handler, Domain, Service y Selector. Implementación propia y ligera.
2. El comportamiento actual debe mantenerse, salvo los bugs que encuentres. Documenta cada bug encontrado.
3. Todo debe funcionar con 200 registros en una sola transacción.

### Parte 2 — Nuevo requerimiento

El área comercial pide que el descuento dependa del tipo de cliente (`Account.Customer_Segment__c`):

| Segmento | Regla |
| --- | --- |
| Retail | 2% si el monto es mayor a 20,000 |
| Corporate | 5% fijo |
| Fleet | 3% por cada 5 vehículos (`Vehicle_Count__c`), máximo 12% |

Además, al entrar a `Credit Review`, se debe consultar el servicio externo de scoring (`POST /v1/score`, contrato en `docs/score-api.md`) y guardar el resultado en `Credit_Score__c` y `Credit_Status__c`.

Se espera que el diseño permita agregar un segmento nuevo sin modificar las clases existentes.

### Parte 3 — Seguridad

Entrega un Permission Set con el mínimo necesario para que el perfil "Analista de Crédito" use esta funcionalidad. Justifica cada permiso.

### Entregables

- [ ] Repo SFDX
- [ ] Tests con cobertura mayor a 75% y asserts con significado
- [ ] `DECISIONS.md`: máximo 1 página. Qué patrón usaste, dónde, qué principio SOLID resuelve y dónde decidiste **no** aplicar uno
- [ ] `ASSUMPTIONS.md`: lo que interpretaste del requerimiento y por qué
- [ ] `AI_USAGE.md`: qué herramientas usaste, para qué partes, y un ejemplo de algo que la IA sugirió y tú corregiste o rechazaste

### Reglas sobre IA

Puedes usar cualquier herramienta de IA. En la entrevista de seguimiento modificarás tu propio código en vivo, sin IA, y explicarás tus decisiones. Entregar algo que no puedes explicar cuenta más en contra que entregar algo incompleto.

Tiempo sugerido: 3 horas.



