-- 09_finance.sql

CREATE TABLE taxes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL, -- e.g., 'VAT', 'Sales Tax'
    rate DECIMAL(5, 2) NOT NULL, -- percentage
    country VARCHAR(100) NOT NULL,
    region VARCHAR(100)
);

CREATE TABLE accounts_receivable (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID REFERENCES customers(id) ON DELETE RESTRICT,
    order_id UUID REFERENCES orders(id) ON DELETE RESTRICT,
    amount_due DECIMAL(12, 2) NOT NULL,
    due_date DATE NOT NULL,
    status VARCHAR(50) DEFAULT 'OPEN', -- OPEN, PARTIAL, PAID
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE bank_reconciliations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID REFERENCES transactions(id) ON DELETE RESTRICT,
    bank_statement_id VARCHAR(100),
    reconciled_amount DECIMAL(12, 2) NOT NULL,
    reconciled_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    reconciled_by UUID REFERENCES users(id) ON DELETE RESTRICT
);
