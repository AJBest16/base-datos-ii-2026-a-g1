-- 04_inventory.sql

CREATE TABLE warehouses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    location VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE aisles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    warehouse_id UUID REFERENCES warehouses(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    UNIQUE (warehouse_id, name)
);

CREATE TABLE shelves (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    aisle_id UUID REFERENCES aisles(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    UNIQUE (aisle_id, name)
);

CREATE TABLE stock (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_variant_id UUID REFERENCES product_variants(id) ON DELETE CASCADE,
    warehouse_id UUID REFERENCES warehouses(id) ON DELETE RESTRICT,
    shelf_id UUID REFERENCES shelves(id) ON DELETE SET NULL,
    quantity INTEGER NOT NULL DEFAULT 0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (product_variant_id, warehouse_id, shelf_id)
);

CREATE TABLE stock_movements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    stock_id UUID REFERENCES stock(id) ON DELETE RESTRICT,
    user_id UUID REFERENCES users(id) ON DELETE RESTRICT,
    quantity_change INTEGER NOT NULL,
    reason VARCHAR(100) NOT NULL,
    movement_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE inventory_audits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    warehouse_id UUID REFERENCES warehouses(id) ON DELETE RESTRICT,
    user_id UUID REFERENCES users(id) ON DELETE RESTRICT,
    status VARCHAR(50) DEFAULT 'IN_PROGRESS',
    audit_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
