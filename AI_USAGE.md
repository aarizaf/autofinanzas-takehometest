# AI_USAGE

## Herramientas

- **Claude Code** (extensión de VS Code, modelo Claude Sonnet 5.5).
- Salesforce CLI para desplegar en una Developer Edition y correr los tests (lo ejecutó Claude Code a petición mía).

## Para qué partes

| Parte | Uso de la IA |
|---|---|
| Análisis del código original | Me guió con preguntas para encontrar bugs; yo ya había detectado el SOQL dentro del `for`. |
| Refactor en capas | Escribió el borrador de las capas; yo pedí organizarlo por carpetas y simplificar el código. |
| Strategy de descuentos | Propuso el patrón y una primera versión con Factory y Custom Metadata. |
| Scoring (Queueable y cliente HTTP) | Escribió el borrador de las dos clases y los tests con mock. |
| Tests | Escribió los tests; los fui leyendo y ejecutando en mi org. |
| Permission Set (Parte 3) | Escribió el borrador del Permission Set y un test con un usuario real del perfil para comprobarlo. |
| Documentos | Redactó el borrador a partir de lo que hicimos en la sesión. |

## Ejemplos de algo que la IA sugirió y yo corregí o rechacé

1. **Faltaba el header `x-api-key`.** La primera versión de `ScoreApiClient` no lo enviaba: la IA había dado por hecho que una Named Credential lo agregaría, pero esa credencial nunca se creó. Lo noté al leer la clase, se lo señalé, y decidimos guardar la URL y la clave en un Custom Metadata (`Score_Api_Config__mdt`) y enviarla en el header.
2. **Rechacé la complejidad del diseño inicial.** La IA propuso para los segmentos un Factory más un Custom Metadata Type con 3 registros. Le dije que había demasiadas clases y demasiado código para explicar en la entrevista. Lo reemplazamos por una convención de nombres (`segmento + 'Discount'`) dentro del Domain, sin Factory ni metadata.
3. **Cambio del encadenamiento de jobs.** La IA recomendó un Queueable que procesa 100 oportunidades y se encadena a sí mismo. Al correr los tests apareció `Maximum stack depth has been reached` (Salesforce no permite encadenar jobs en tests). Cambiamos a un job independiente por cada grupo de 100.
4. **Suposición errónea sobre los permisos.** La IA planteó primero un Permission Set de solo lectura, asumiendo que el código de Apex no necesitaba permisos de campo. Al probarlo con un usuario real del perfil, el trigger falló por no poder leer `Account.Customer_Segment__c` (y `Account.Type`, que el Selector consultaba sin usarla), y el job falló por no poder editar `Credit_Score__c` y `Credit_Status__c`. Se ajustó el Permission Set y se quitó `Type` de la query.



