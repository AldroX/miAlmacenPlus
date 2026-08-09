# Mi Almacén — Prompt Maestro para desarrollo del MVP

Quiero desarrollar una aplicación llamada **Mi Almacén**.

La aplicación será una solución mobile-first para la gestión sencilla de inventario, orientada principalmente a:

- Pequeños emprendedores.
- Personas que venden productos desde casa.
- Personas que necesitan controlar productos de su hogar.
- Pequeños almacenes que no necesitan un ERP complejo.

El objetivo es construir primero un **MVP funcional, mantenible y escalable**, evitando sobreingeniería y funcionalidades innecesarias.

---

# 1. Visión del producto

Mi Almacén debe permitir responder rápidamente tres preguntas:

> **¿Qué productos tengo?**

> **¿Cuánto tengo actualmente?**

> **¿Qué ocurrió con mi inventario?**

El concepto central del sistema es:

```text
Producto
    ↓
Stock actual
    ↓
Movimientos
    ↓
Historial / trazabilidad
```

El usuario no debe modificar arbitrariamente el stock.

El stock debe cambiar como consecuencia de una operación de inventario.

```text
Entrada
    ↓
Movimiento
    ↓
Actualización del stock
```

o:

```text
Salida
    ↓
Validación
    ↓
Movimiento
    ↓
Actualización del stock
```

---

# 2. Objetivo del MVP

El MVP debe permitir que un usuario:

1. Crear una cuenta.
2. Iniciar sesión.
3. Crear productos.
4. Editar productos.
5. Consultar productos.
6. Desactivar productos.
7. Registrar entradas de inventario.
8. Registrar salidas de inventario.
9. Consultar el stock actual.
10. Consultar el historial de movimientos.
11. Buscar productos.
12. Filtrar productos.
13. Identificar productos con stock bajo.
14. Evitar salidas superiores al stock disponible.
15. Consultar un dashboard básico del inventario.

No implementar funcionalidades avanzadas que no sean necesarias para validar este MVP.

---

# 3. Usuarios y aislamiento de datos

El sistema debe diseñarse desde el principio pensando en múltiples usuarios.

Cada usuario debe tener acceso únicamente a sus propios datos.

Conceptualmente:

```text
User
 └── Products
      └── Movements
```

Un usuario no debe poder consultar, modificar o eliminar información perteneciente a otro usuario.

La arquitectura debe permitir posteriormente evolucionar hacia:

```text
User
 └── Workspace
      ├── Members
      ├── Products
      ├── Categories
      └── Movements
```

Sin necesidad de reconstruir completamente el dominio.

Para el MVP, puede existir una relación simple:

```text
User → Products
```

pero no diseñar el código de manera que impida introducir posteriormente organizaciones/workspaces.

---

# 4. Dominio principal

Las entidades principales del MVP son:

```text
User
Product
Category
InventoryMovement
```

---

# 5. Product

Un producto representa un elemento que el usuario desea controlar.

Debe contemplar como mínimo:

```text
id
userId
name
description
categoryId
unit
currentStock
minimumStock
isActive
createdAt
updatedAt
```

El modelo debe poder evolucionar posteriormente para soportar:

- SKU.
- Código de barras.
- Imagen.
- Precio de compra.
- Precio de venta.
- Proveedor.
- Ubicación.
- Diferentes unidades de medida.

No implementar estas funcionalidades si no son necesarias para el MVP.

---

# 6. Category

Las categorías permiten organizar los productos.

Ejemplos:

```text
Alimentos
Bebidas
Limpieza
Higiene
Electrónica
Herramientas
Otros
```

El usuario debe poder:

- Crear categoría.
- Editar categoría.
- Consultar categorías.
- Desactivar categoría si es necesario.

No permitir eliminar una categoría si esto genera inconsistencias con productos existentes.

Preferir desactivación cuando corresponda.

---

# 7. InventoryMovement

Esta es una de las entidades más importantes del sistema.

Cada modificación del inventario debe generar un movimiento.

Campos conceptuales:

```text
id
productId
userId
type
quantity
reason
stockBefore
stockAfter
note
createdAt
```

El tipo debe ser:

```text
IN
OUT
```

Ejemplos de motivos:

```text
PURCHASE
SALE
CONSUMPTION
RETURN
LOSS
ADJUSTMENT
OTHER
```

Los motivos pueden evolucionar posteriormente.

---

# 8. Regla fundamental de inventario

El stock actual debe mantenerse consistente con los movimientos.

### Entrada

Ejemplo:

```text
Stock actual: 20
Entrada: 10
```

Resultado:

```text
stockBefore = 20
quantity = 10
stockAfter = 30
```

El producto termina con:

```text
currentStock = 30
```

### Salida

Ejemplo:

```text
Stock actual: 30
Salida: 5
```

Resultado:

```text
stockBefore = 30
quantity = 5
stockAfter = 25
```

El producto termina con:

```text
currentStock = 25
```

---

# 9. Prohibición de stock negativo

Nunca debe permitirse:

```text
currentStock < 0
```

Ejemplo:

```text
Stock actual: 3
Salida solicitada: 5
```

La operación debe rechazarse.

El frontend debe mostrar un mensaje comprensible.

Pero la validación **también debe existir en el backend**.

Nunca confiar únicamente en las validaciones del cliente.

---

# 10. Atomicidad

Registrar un movimiento y actualizar el stock debe ser una única operación lógica.

No debe ocurrir:

```text
Movimiento creado
↓
Error actualizando stock
```

dejando datos inconsistentes.

Debe utilizarse una transacción cuando el backend y la base de datos lo permitan:

```text
BEGIN TRANSACTION

1. Obtener producto
2. Validar stock
3. Calcular nuevo stock
4. Crear movimiento
5. Actualizar producto

COMMIT
```

Si cualquier operación falla:

```text
ROLLBACK
```

---

# 11. Concurrencia

El sistema debe considerar que dos operaciones pueden intentar modificar el mismo producto casi simultáneamente.

Evitar condiciones de carrera como:

```text
Stock = 10

Request A → salida 7
Request B → salida 6

Ambas leen stock = 10

Resultado incorrecto
```

La operación de inventario debe diseñarse de manera que el stock permanezca consistente incluso ante solicitudes concurrentes.

La solución concreta debe adaptarse al stack de backend y base de datos utilizado.

---

# 12. CRUD de productos

Implementar:

### Crear

El usuario proporciona:

```text
Nombre
Descripción
Categoría
Unidad
Cantidad inicial
Stock mínimo
```

La cantidad inicial debe generar el estado inicial del inventario.

Idealmente debe existir también un movimiento inicial:

```text
type = IN
reason = INITIAL_STOCK
```

para mantener la trazabilidad desde el comienzo.

### Leer

Permitir:

- Lista de productos.
- Detalle del producto.
- Stock actual.
- Categoría.
- Estado del inventario.

### Actualizar

Permitir editar información descriptiva:

```text
Nombre
Descripción
Categoría
Unidad
Stock mínimo
```

No utilizar la edición normal del producto para modificar directamente el stock.

### Eliminar

Preferir:

```text
soft delete / desactivación
```

en lugar de eliminar físicamente productos que ya tienen movimientos.

Esto preserva la trazabilidad.

---

# 13. Estados del inventario

Un producto debe poder clasificarse visualmente como:

```text
NORMAL
LOW_STOCK
OUT_OF_STOCK
```

Regla conceptual:

```text
currentStock == 0
    → OUT_OF_STOCK

currentStock <= minimumStock
    → LOW_STOCK

currentStock > minimumStock
    → NORMAL
```

El frontend debe representar estos estados claramente.

No depender exclusivamente del color para comunicar el estado.

---

# 14. Dashboard

El dashboard del MVP debe ser simple.

Debe mostrar información como:

```text
Total de productos
Productos con stock bajo
Productos agotados
Movimientos recientes
```

Opcionalmente:

```text
Total de unidades
Entradas recientes
Salidas recientes
```

No crear dashboards excesivamente complejos.

El objetivo es que el usuario pueda entender el estado de su inventario rápidamente.

---

# 15. Lista de productos

Debe incluir:

```text
Buscar
Filtrar
Ordenar
```

Cada producto debe mostrar como mínimo:

```text
Nombre
Stock actual
Unidad
Estado del stock
```

Debe ser posible entrar al detalle.

---

# 16. Detalle de producto

Debe mostrar:

```text
Nombre
Descripción
Categoría
Stock actual
Stock mínimo
Estado
```

Y acciones principales:

```text
Registrar entrada
Registrar salida
```

Además:

```text
Historial de movimientos
```

El stock actual debe tener una jerarquía visual superior al resto de la información.

---

# 17. Registro de entrada

Flujo:

```text
Seleccionar producto
↓
Seleccionar cantidad
↓
Seleccionar motivo
↓
Agregar nota opcional
↓
Confirmar
↓
Actualizar stock
↓
Crear movimiento
↓
Mostrar resultado
```

Ejemplo:

```text
Producto: Café 250g

Stock actual
52 unidades

Cantidad
8

Motivo
Compra

Nota
Compra semanal

[Registrar entrada]
```

---

# 18. Registro de salida

Flujo:

```text
Seleccionar producto
↓
Seleccionar cantidad
↓
Seleccionar motivo
↓
Agregar nota opcional
↓
Validar stock
↓
Confirmar
↓
Actualizar stock
↓
Crear movimiento
↓
Mostrar resultado
```

Ejemplo:

```text
Stock disponible: 52

Cantidad:
8

Motivo:
Venta
```

Si intenta introducir:

```text
Cantidad: 60
```

debe rechazarse.

---

# 19. Historial

El usuario debe poder consultar los movimientos de un producto.

Cada movimiento debe mostrar:

```text
Tipo
Cantidad
Motivo
Fecha
Stock anterior
Stock posterior
```

Ejemplo:

```text
Hoy

ENTRADA +20
Compra

Stock:
40 → 60

08/08/2026


SALIDA -5
Venta

Stock:
60 → 55
```

El historial es una característica fundamental del producto porque proporciona trazabilidad.

---

# 20. UX/UI Mobile

La aplicación será desarrollada para dispositivos móviles.

El diseño debe ser:

- Mobile-first.
- Limpio.
- Moderno.
- Minimalista.
- Accesible.
- Fácil de utilizar con una mano.
- Con targets táctiles adecuados.
- Con navegación sencilla.

Evitar:

- Tablas complejas.
- Formularios excesivamente largos.
- Interfaces tipo ERP.
- Exceso de información simultánea.
- Decoración innecesaria.

Las acciones principales deben ser evidentes:

```text
+ Entrada
- Salida
+ Nuevo producto
```

Utilizar componentes apropiados para mobile:

```text
Bottom sheets
Dialogs
Floating Action Buttons
Cards
Lists
Chips
Snackbars
Empty states
Confirmation dialogs
```

---

# 21. Estados de UI

Todas las pantallas deben contemplar:

```text
Loading
Success
Empty
Error
Offline / Network failure
Validation error
```

Ejemplos:

### Sin productos

```text
Todavía no tienes productos.

Agrega tu primer producto
para comenzar a controlar tu inventario.
```

### Sin movimientos

```text
Este producto todavía no tiene movimientos.
```

### Stock agotado

Mostrar claramente:

```text
0 unidades
Agotado
```

---

# 22. Arquitectura Flutter

Utilizar una arquitectura que permita crecer sin convertir el proyecto en un monolito.

Separar claramente:

```text
Presentation
Domain
Data
```

Conceptualmente:

```text
lib/
├── core/
├── features/
│   ├── auth/
│   ├── products/
│   ├── categories/
│   ├── inventory/
│   └── dashboard/
└── ...
```

La estructura concreta puede adaptarse al framework y librerías seleccionadas.

Evitar introducir abstracciones innecesarias.

La arquitectura debe facilitar:

- Testing.
- Mantenimiento.
- Separación de responsabilidades.
- Reutilización.
- Evolución del dominio.

---

# 23. Estado en Flutter

Utilizar un patrón de gestión de estado consistente en toda la aplicación.

La solución debe:

- Evitar estado global innecesario.
- Mantener la lógica de negocio fuera de widgets.
- Facilitar testing.
- Gestionar estados de loading/error/success.
- Permitir actualización automática del stock después de un movimiento.

No mezclar lógica de negocio directamente dentro de widgets.

---

# 24. Backend

El backend debe exponer una API clara y versionable.

Por ejemplo:

```text
/api/v1/auth
/api/v1/products
/api/v1/categories
/api/v1/inventory
/api/v1/movements
/api/v1/dashboard
```

La implementación concreta puede utilizar:

```text
NestJS
PostgreSQL
```

si este es el stack seleccionado.

Utilizar:

- DTOs.
- Validación.
- Autenticación.
- Autorización.
- Manejo consistente de errores.
- Transacciones.
- Logging.
- Configuración mediante variables de entorno.

---

# 25. Base de datos

Utilizar PostgreSQL.

El esquema debe diseñarse considerando:

- Relaciones claras.
- Índices apropiados.
- Foreign keys.
- Constraints.
- Timestamps.
- Soft delete cuando sea necesario.

Especial atención a:

```text
Product → Category
Product → Movements
User → Products
User → Movements
```

No duplicar información innecesariamente.

---

# 26. Seguridad

Implementar desde el MVP:

- Autenticación.
- Hash seguro de contraseñas.
- JWT o mecanismo equivalente.
- Validación de permisos.
- Aislamiento de datos por usuario.
- Validación de inputs.
- Protección contra acceso a recursos de otros usuarios.
- Variables sensibles fuera del código fuente.

Nunca confiar en:

```text
userId enviado por el frontend
```

para determinar la identidad del usuario.

El backend debe obtener la identidad a partir del contexto autenticado.

---

# 27. Validaciones

Validar tanto frontend como backend.

Ejemplos:

```text
Nombre requerido
Cantidad > 0
Stock mínimo >= 0
Categoría válida
Producto existente
Producto perteneciente al usuario
Stock suficiente para una salida
```

El backend debe ser la autoridad final.

---

# 28. Manejo de errores

Definir respuestas consistentes.

Ejemplo conceptual:

```json
{
  "statusCode": 400,
  "code": "INSUFFICIENT_STOCK",
  "message": "Insufficient stock for this operation"
}
```

El frontend debe traducir estos errores a mensajes comprensibles para el usuario.

Evitar mostrar mensajes técnicos directamente.

---

# 29. Testing

El MVP debe incluir testing suficiente para garantizar las reglas críticas.

### Unit tests

Probar principalmente:

- Creación de producto.
- Cálculo de stock.
- Entrada.
- Salida.
- Stock insuficiente.
- Estados del inventario.
- Validaciones.

### Integration tests

Probar:

```text
Crear producto
↓
Registrar entrada
↓
Verificar stock
↓
Registrar salida
↓
Verificar stock
↓
Consultar historial
```

### Flutter widget tests

Probar las pantallas y componentes críticos:

- Login.
- Lista de productos.
- Detalle.
- Entrada.
- Salida.
- Estados de loading/error/empty.

Priorizar las reglas de negocio sobre el porcentaje de cobertura.

---

# 30. Observabilidad

Preparar el proyecto para poder diagnosticar errores posteriormente.

Implementar una estrategia básica de:

```text
Logging
Error handling
Request tracing
```

No introducir herramientas externas complejas en el MVP si no son necesarias.

La arquitectura debe permitir incorporarlas posteriormente.

---

# 31. Configuración y ambientes

Separar:

```text
Development
Staging
Production
```

Las configuraciones sensibles deben utilizar variables de entorno.

Nunca almacenar:

```text
API keys
JWT secrets
Database credentials
```

directamente en el repositorio.

---

# 32. API y documentación

Documentar la API.

Idealmente utilizar OpenAPI / Swagger.

Documentar:

- Endpoints.
- Request DTOs.
- Response DTOs.
- Errores.
- Autenticación.

La documentación debe mantenerse junto al código.

---

# 33. Reglas de diseño importantes

No implementar funcionalidades simplemente porque "podrían ser útiles".

Para cada funcionalidad preguntarse:

> ¿Es necesaria para validar el concepto principal de Mi Almacén?

Si la respuesta es no, dejarla fuera del MVP.

No implementar inicialmente:

- Facturación.
- Punto de venta.
- Contabilidad.
- Proveedores avanzados.
- Compras completas.
- Ventas completas.
- Multi-almacén.
- Reportes financieros complejos.
- Roles empresariales complejos.
- Integración con marketplaces.
- Código de barras.
- IA.
- Notificaciones push complejas.

Estas funcionalidades pueden formar parte del roadmap.

---

# 34. Roadmap posterior al MVP

Diseñar el sistema para poder incorporar posteriormente:

```text
Multi-workspace
    ↓
Miembros y roles
    ↓
Múltiples almacenes
    ↓
Código de barras
    ↓
Proveedores
    ↓
Compras
    ↓
Ventas
    ↓
Reportes
    ↓
Notificaciones
    ↓
Integraciones
```

También podría evolucionar hacia:

```text
Hogar
   ↓
Inventario personal

Emprendedor
   ↓
Inventario comercial

Pequeño negocio
   ↓
Workspace
   ↓
Miembros
   ↓
Roles
   ↓
Múltiples almacenes
```

No implementar estas capacidades ahora, solamente mantener el dominio preparado para ellas.

---

# 35. Principios de desarrollo

Durante el desarrollo seguir estas reglas:

### KISS

Mantener las soluciones simples.

### SOLID

Aplicar separación de responsabilidades donde aporte valor real.

### DRY

Evitar duplicación significativa.

### YAGNI

No implementar funcionalidades futuras antes de necesitarlas.

### Domain-driven thinking

El dominio principal es:

```text
Product
Inventory
Movement
```

La lógica de inventario debe estar claramente separada de la presentación.

---

# 36. Desarrollo incremental

No intentar desarrollar toda la aplicación de una sola vez.

Trabajar por fases.

## Fase 1 — Foundation

- Crear proyecto.
- Configuración.
- Arquitectura base.
- Theme.
- Navegación.
- Networking.
- Manejo de errores.
- Configuración de ambientes.

## Fase 2 — Authentication

- Registro.
- Login.
- Logout.
- Persistencia de sesión.

## Fase 3 — Products

- Crear.
- Listar.
- Consultar.
- Editar.
- Desactivar.
- Buscar.
- Filtrar.

## Fase 4 — Inventory

- Entrada.
- Salida.
- Validación de stock.
- Actualización transaccional.
- Historial.

## Fase 5 — Dashboard

- Resumen.
- Stock bajo.
- Agotados.
- Movimientos recientes.

## Fase 6 — Testing

- Unit tests.
- Integration tests.
- Widget tests.
- Flujos críticos.

## Fase 7 — Refinamiento

- UX.
- Loading states.
- Empty states.
- Error states.
- Accesibilidad.
- Performance.

---

# 37. Criterios de aceptación del MVP

El MVP se considera funcional cuando un usuario puede completar este flujo:

```text
Registrar cuenta
        ↓
Iniciar sesión
        ↓
Crear producto
        ↓
Definir stock inicial
        ↓
Consultar producto
        ↓
Registrar entrada
        ↓
Ver nuevo stock
        ↓
Registrar salida
        ↓
Ver nuevo stock
        ↓
Consultar historial
        ↓
Ver stock anterior y posterior
```

Y debe cumplirse:

```text
Stock nunca negativo
        +
Movimientos nunca inconsistentes
        +
Datos aislados por usuario
        +
Historial preservado
        +
Operaciones críticas transaccionales
```

---

# 38. Resultado esperado

Quiero obtener una aplicación mobile de inventario que sea:

- Simple para un usuario común.
- Suficientemente profesional para un pequeño emprendedor.
- Fácil de mantener.
- Fácil de probar.
- Segura.
- Consistente.
- Escalable.
- Preparada para evolucionar.

La prioridad debe ser:

```text
Correctitud del inventario
        ↓
Experiencia de usuario
        ↓
Mantenibilidad
        ↓
Escalabilidad
```

No sacrificar la simplicidad del MVP intentando construir desde el primer día un ERP completo.

---

# 39. Instrucción final para la IA

Antes de implementar cualquier funcionalidad:

1. Analiza el requerimiento.
2. Identifica qué parte del dominio afecta.
3. Verifica si pertenece realmente al MVP.
4. Propón una solución simple.
5. Identifica posibles problemas de consistencia o seguridad.
6. Implementa.
7. Añade o actualiza los tests correspondientes.
8. Verifica que las funcionalidades existentes no se rompan.
9. Documenta decisiones arquitectónicas importantes.

No generes grandes cantidades de código de una sola vez.

Trabaja incrementalmente y mantén el proyecto compilable y ejecutable después de cada fase.

Si existe una decisión técnica ambigua, prioriza:

```text
Simplicidad
+
Correctitud
+
Mantenibilidad
+
Escalabilidad razonable
```

sobre soluciones excesivamente sofisticadas.

El objetivo no es construir "la aplicación de inventario definitiva".

El objetivo es construir una **primera versión sólida de Mi Almacén**, validar el producto y dejar una base técnica preparada para crecer.