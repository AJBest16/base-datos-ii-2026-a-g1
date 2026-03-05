# Arquitectura de la Base de Datos "Aviones"

He analizado a detalle el archivo `Merrr Aviones.drawio`. Se trata de un modelo relacional sumamente completo (más de **80 tablas**), dividido inteligentemente en 15 módulos diferentes.

Debido al tamaño de la base de datos, si generamos un único diagrama `Mermaid` con todo, se verá demasiado saturado e ilegible. Por lo tanto, he estructurado los Diagramas de Entidad-Relación (DER) organizados por sus respectivos módulos.

### 1. Identity & Security (Identidad y Seguridad)
Gestiona la información de las personas y el sistema de acceso mediante roles y permisos.

```mermaid
erDiagram
    PERSON ||--o{ DOCUMENT_IDENTITY : tiene
    PERSON ||--o{ CONTACT_INFORMATION : tiene
    TYPE_PERSON ||--o{ PERSON : clasifica
    TYPE_DOCUMENT ||--o{ DOCUMENT_IDENTITY : clasifica
    PERSON ||--o{ USER_ACCOUNT : posee
    STATUS_USER ||--o{ USER_ACCOUNT : clasifica

    PERSON {
        string id PK
        string type_person_id FK
    }
    DOCUMENT_IDENTITY {
        string id PK
        string person_id FK
        string type_document_id FK
    }
    USER_ACCOUNT {
        string id PK
        string person_id FK
        string status_user_id FK
    }
    USER_ROLE {
        string id PK
        string user_account_id FK
        string role_id FK
    }
    ROLE_PERMISSION {
        string id PK
        string role_id FK
        string permission_id FK
    }
```

### 2. Aircfraft & Airport (Aeronaves y Aeropuertos)
Controla el estado de las aeronaves, los modelos, sus asientos y las infraestructuras aeroportuarias físicas.

```mermaid
erDiagram
    AIRCRAFT ||--o{ CABIN_CONFIGURATION : tiene
    AIRCRAFT_MODEL ||--o{ AIRCRAFT : modelo_de
    CABIN_CONFIGURATION ||--o{ SEAT : contiene
    AIRCRAFT ||--o{ MAINTENANCE_HISTORY : recibe

    AIRPORT ||--o{ TERMINAL : tiene
    AIRPORT ||--o{ RUNWAY : tiene
    TERMINAL ||--o{ BOARDING_GATE : posee
    
    AIRCRAFT {
        string id PK
        string aircraft_model_id FK
        string status_aircraft_id FK
    }
    CABIN_CONFIGURATION {
        string id PK
        string aircraft_id FK
    }
    SEAT {
        string id PK
        string cabin_configuration_id FK
        string type_seat_id FK
        string fare_class_id FK
    }
    AIRPORT {
        string id PK
        string geolocation_id FK
    }
    TERMINAL {
        string id PK
        string airport_id FK
    }
    BOARDING_GATE {
        string id PK
        string terminal_id FK
    }
```

### 3. Flights & Boarding (Vuelos y Abordaje)
Estructura los segmentos de vuelo, las estaciones de origen/destino y el flujo de los pasajeros para el pase de abordar.

```mermaid
erDiagram
    AIRCRAFT ||--o{ FLIGHT : asignado_a
    AIRPORT ||--o{ FLIGHT : origen_destino
    FLIGHT ||--o{ FLIGHT_SEGMENT : se_divide_en
    FLIGHT ||--o{ FLIGHT_DELAY_REASON : registra

    TICKET ||--o{ CHECK_IN : origina
    TICKET ||--o{ BOARDING_PASS : genera
    BOARDING_PASS ||--o{ BOARDING_VALIDATION : validado_en

    FLIGHT {
        string id PK
        string aircraft_id FK
        string origin_airport_id FK
        string destination_airport_id FK
        string status_flight_id FK
    }
    FLIGHT_SEGMENT {
        string id PK
        string flight_id FK
        string origin_airport_id FK
        string destination_airport_id FK
    }
    BOARDING_PASS {
        string id PK
        string ticket_id FK
        string flight_segment_id FK
        string boarding_group_id FK
    }
    BOARDING_VALIDATION {
        string id PK
        string boarding_pass_id FK
        string boarding_gate_id FK
    }
```

### 4. Sales, Payment & Billing (Ventas, Pagos y Facturación)
El ecosistema de compras, donde una Venta se relaciona a las Reservas, Entradas (Tickets) y Equipaje, culminando en transacciones financieras e impuestos.

```mermaid
erDiagram
    CUSTOMER ||--o{ SALE : realiza
    SALE ||--o{ RESERVATION : crea
    SALE ||--o{ TICKET : compra
    TICKET ||--o{ BAGGAGE : documenta
    
    SALE ||--o{ PAYMENT : pagado_con
    PAYMENT ||--o{ PAYMENT_TRANSACTION : registra
    PAYMENT ||--o{ REFUND : puede_tener
    
    SALE ||--o{ INVOICE : factura

    SALE {
        string id PK
        string person_customer_id FK
        string status_sale_id FK
    }
    RESERVATION {
        string id PK
        string sale_id FK
        string status_reservation_id FK
    }
    TICKET {
        string id PK
        string sale_id FK
        string person_passenger_id FK
        string flight_segment_id FK
        string status_ticket_id FK
    }
    PAYMENT {
        string id PK
        string sale_id FK
        string type_payment_method_id FK
        string status_payment_id FK
    }
    INVOICE {
        string id PK
        string sale_id FK
        string currency_id FK
    }
```

### 5. Geo, Crew, Cargo & Notifications
Manejo de rutas geográficas, horarios de la tripulación en base al vuelo, envío de carga y sistema de envío de notificaciones.

```mermaid
erDiagram
    CONTINENT ||--o{ COUNTRY : contiene
    COUNTRY ||--o{ STATE : contiene
    STATE ||--o{ CITY : contiene
    
    PERSON ||--o{ CREW_MEMBER : puede_ser
    CREW_MEMBER ||--o{ CREW_ASSIGNMENT : asignado_a
    FLIGHT ||--o{ CREW_ASSIGNMENT : operado_por
    
    FLIGHT ||--o{ CARGO_BOOKING : transporta
    CARGO_BOOKING ||--o{ CARGO_SHIPMENT : genera
    CARGO_SHIPMENT ||--o{ CARGO_ITEM : contiene
    
    NOTIFICATION_TEMPLATE ||--o{ NOTIFICATION : usa
    PERSON ||--o{ NOTIFICATION : recibe

    GEOLOCATION {
        string id PK
        string country_id FK
        string state_id FK
        string city_id FK
        string district_id FK
        string address_id FK
        string coordinate_id FK
    }
    CREW_ASSIGNMENT {
        string id PK
        string crew_member_id FK
        string flight_id FK
        string type_crew_role_id FK
    }
    CARGO_BOOKING {
        string id PK
        string cargo_customer_id FK
        string flight_id FK
        string status_cargo_booking_id FK
    }
    NOTIFICATION {
        string id PK
        string person_id FK
        string notification_template_id FK
    }
```

> [!NOTE]
> Las sub-tablas ruteadoras estáticas (como `type_currency`, `status_payment`, `status_crew`) han sido omitidas gráficamente del diagrama Mermaid arriba para concentrarnos en dar una visión directa de la arquitectura, aunque en el script detectamos que sí están vinculadas correctamente mediante IDs y las tablas están perfectamente normalizadas.
