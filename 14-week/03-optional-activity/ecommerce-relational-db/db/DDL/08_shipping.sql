-- 08_shipping.sql

CREATE TABLE carriers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    tracking_url_template VARCHAR(255),
    is_active BOOLEAN DEFAULT true
);

CREATE TABLE shipping_zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    region VARCHAR(100)
);

CREATE TABLE shipping_rates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    carrier_id UUID REFERENCES carriers(id) ON DELETE CASCADE,
    shipping_zone_id UUID REFERENCES shipping_zones(id) ON DELETE CASCADE,
    weight_up_to DECIMAL(10, 2), -- max weight for this rate
    price DECIMAL(12, 2) NOT NULL
);

CREATE TABLE routes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    origin_warehouse_id UUID REFERENCES warehouses(id) ON DELETE RESTRICT,
    destination_zone_id UUID REFERENCES shipping_zones(id) ON DELETE RESTRICT,
    estimated_days INTEGER
);

CREATE TABLE shipment_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    carrier_id UUID REFERENCES carriers(id) ON DELETE RESTRICT,
    tracking_number VARCHAR(100) NOT NULL,
    status VARCHAR(50) DEFAULT 'DISPATCHED', -- DISPATCHED, IN_TRANSIT, OUT_FOR_DELIVERY, DELIVERED
    dispatched_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    delivered_at TIMESTAMP WITH TIME ZONE
);
