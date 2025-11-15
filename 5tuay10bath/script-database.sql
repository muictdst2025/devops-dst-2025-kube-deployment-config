CREATE DATABASE IF NOT EXISTS 5tuay10bath_db;

\c 5tuay10bath_db;

CREATE TABLE IF NOT EXISTS units (
    id                      UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    unit_number             VARCHAR(10)     NOT NULL,
    address                 TEXT            NOT NULL    UNIQUE,
    unit_type               VARCHAR(20)     NOT NULL    CHECK (unit_type IN ('A', 'B', 'C')),
    unit_size               DECIMAL(5, 2)   NOT NULL    CHECK (unit_size >= 0),
    status                  VARCHAR(20)     NOT NULL    DEFAULT 'AVAILABLE' CHECK (status IN ('AVAILABLE', 'PENDING', 'RESERVED', 'OCCUPIED')),
    floor                   INT             NOT NULL    CHECK (floor >= 1),
    latest_aircon_service   DATE,
    created_at              TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),
    updated_at              TIMESTAMPTZ     NOT NULL    DEFAULT NOW()
    );

CREATE TABLE IF NOT EXISTS users (
    id                      UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name              VARCHAR(50)     NOT NULL,
    last_name               VARCHAR(50)     NOT NULL,
    phone                   VARCHAR(15)     NOT NULL,
    email                   VARCHAR(50)     NOT NULL    UNIQUE,
    password                VARCHAR(254)    NOT NULL,
    role                    VARCHAR(20)     NOT NULL    DEFAULT 'USER'  CHECK (role IN ('USER', 'ADMIN', 'TENANT', 'STAFF')),
    identification_number   CHAR(13)        NOT NULL    UNIQUE  CHECK (LENGTH(identification_number) = 13),
    profile_image_url       TEXT,
    birth_date              DATE,
    active                  BOOLEAN         NOT NULL    DEFAULT FALSE,
    emergency_contact_name  VARCHAR(100),
    emergency_contact_phone VARCHAR(15),
    created_at              TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),
    updated_at              TIMESTAMPTZ     NOT NULL    DEFAULT NOW()
    );

CREATE TABLE IF NOT EXISTS maintenances (
                                            id
                                            UUID
                                            PRIMARY
                                            KEY
                                            DEFAULT
                                            gen_random_uuid
(
),
    unit_id UUID NOT NULL REFERENCES units
(
    id
) ON DELETE CASCADE,
    title VARCHAR
(
    50
) NOT NULL,
    description TEXT,
    price DECIMAL
(
    10,
    2
) NOT NULL DEFAULT 0,
    priority VARCHAR
(
    10
) CHECK
(
    priority
    IN
(
    'LOW',
    'MEDIUM',
    'HIGH',
    'URGENT'
)),
    maintenance_type VARCHAR
(
    20
) NOT NULL CHECK
(
    maintenance_type
    IN
(
    'ELECTRIC',
    'WATER',
    'PHONE',
    'AIR_CONDITIONAL',
    'FURNITURE',
    'FIRE_ALARM_SYSTEM',
    'WATER_LEAKAGE',
    'FLOOR_WALL',
    'BATHROOM',
    'PAINT',
    'CEMENT_WOOD',
    'OTHER'
)),
    assigned_to UUID REFERENCES users
(
    id
)
  ON DELETE CASCADE,
    reported_by UUID NOT NULL REFERENCES users
(
    id
)
  ON DELETE CASCADE,
    status VARCHAR
(
    20
) NOT NULL DEFAULT 'REPORTED' CHECK
(
    status
    IN
(
    'REPORTED',
    'SCHEDULED',
    'IN_PROGRESS',
    'COMPLETED',
    'CANCELLED'
)),
    scheduled_at TIMESTAMPTZ,
    estimated_finish_time TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW
(
),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW
(
),
    CHECK
(
    scheduled_at <
    estimated_finish_time
)
    );

CREATE TABLE IF NOT EXISTS apartment_configs (
    id                      UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    electric_price_per_unit DECIMAL(10, 2)  NOT NULL    CHECK (electric_price_per_unit >= 0),
    water_price_per_unit    DECIMAL(10, 2)  NOT NULL    CHECK (water_price_per_unit >= 0),
    common_fee              DECIMAL(10, 2)  NOT NULL    CHECK (common_fee >= 0),
    internet_price          DECIMAL(10, 2)  NOT NULL    CHECK (internet_price >= 0),
    created_at              TIMESTAMP       NOT NULL    DEFAULT NOW(),
    updated_at              TIMESTAMP       NOT NULL    DEFAULT NOW()
    );

CREATE TABLE IF NOT EXISTS contracts (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID            NOT NULL    REFERENCES users(id)    ON DELETE CASCADE,
    unit_id             UUID            NOT NULL    REFERENCES units(id)    ON DELETE CASCADE,
    rent_type           VARCHAR(10)     NOT NULL    CHECK (rent_type IN ('MONTHLY', 'YEARLY')),
    rent_amount         DECIMAL(10, 2)  NOT NULL    CHECK (rent_amount >= 0),
    water_billing_type  VARCHAR(25)     NOT NULL    CHECK (water_billing_type IN ('PER_UNIT', 'FLAT_RATE', 'TIERED')),
    internet            BOOLEAN         NOT NULL,
    start_date          DATE            NOT NULL,
    end_date            DATE            NOT NULL,
    status              VARCHAR(20)     NOT NULL    DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'SIGNED', 'ACTIVE', 'EXPIRED')),
    created_at          TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),
    CHECK (start_date < end_date)
    );

CREATE TABLE IF NOT EXISTS invoices (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id         UUID            NOT NULL    REFERENCES contracts(id)    ON DELETE CASCADE,
    apartment_config_id UUID            NOT NULL    REFERENCES apartment_configs(id),
    billing_month       DATE            NOT NULL,
    electric_usage      INT             NOT NULL    CHECK (electric_usage >= 0),
    water_usage         INT             NOT NULL    CHECK (water_usage >= 0),
    status              VARCHAR(10)     NOT NULL    DEFAULT 'UNPAID'    CHECK (status IN ('UNPAID', 'PAID', 'OVERDUE')),
    due_date            TIMESTAMPTZ     NOT NULL,
    total_amount        DECIMAL(10, 2)  NOT NULL    CHECK (total_amount >= 0),
    paid_date           TIMESTAMPTZ,
    created_at          TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),
    CHECK (created_at < due_date),
    CHECK (paid_date IS NULL OR created_at < paid_date)
    );

CREATE TABLE IF NOT EXISTS supplies (
    id          UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(20)     NOT NULL,
    category    VARCHAR(20)     NOT NULL,
    quantity    INT             NOT NULL    DEFAULT 0,
    min_stock   INT             NOT NULL    DEFAULT 0,
    created_at  TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),
    updated_at  TIMESTAMPTZ     NOT NULL    DEFAULT NOW()
    );


-- -- Delete unit will cause maintenance report deleted too
-- ALTER TABLE maintenance_reports
--     DROP CONSTRAINT IF EXISTS maintenance_reports_unit_id_fkey;
-- ALTER TABLE maintenance_reports
--     ADD CONSTRAINT maintenance_reports_unit_id_fkey
--         FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE CASCADE ;
--
-- -- units -> contracts
-- ALTER TABLE contracts
--     DROP CONSTRAINT IF EXISTS contracts_unit_id_fkey;
-- ALTER TABLE contracts
--     ADD CONSTRAINT contracts_unit_id_fkey
--         FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE CASCADE ;
--
-- -- contracts -> invoices
-- ALTER TABLE invoices
--     DROP CONSTRAINT IF EXISTS invoices_contract_id_fkey;
-- ALTER TABLE invoices
--     ADD CONSTRAINT invoices_contract_id_fkey
--         FOREIGN KEY (contract_id) REFERENCES contracts(id) ON DELETE CASCADE ;
--
-- -- user => contracts
-- ALTER TABLE contracts
--     DROP CONSTRAINT IF EXISTS contracts_user_id_fkey;
-- ALTER TABLE contracts
--     ADD CONSTRAINT contracts_user_id_fkey
--         FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ;
--
-- -- users => maintenance
-- ALTER TABLE maintenance_reports
--     DROP CONSTRAINT IF EXISTS maintenance_reports_assigned_to_fkey;
-- ALTER TABLE maintenance_reports
--     ADD CONSTRAINT maintenance_reports_assigned_to_fkey
--         FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE CASCADE ;
--
-- --
-- ALTER TABLE maintenance_reports
--     DROP CONSTRAINT IF EXISTS maintenance_reports_reported_by_fkey;
-- ALTER TABLE maintenance_reports
--     ADD CONSTRAINT maintenance_reports_reported_by_fkey
--         FOREIGN KEY (reported_by) REFERENCES users(id) ON DELETE CASCADE ;

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ======================================================
-- 🏢 Units : 24 rooms (2 floors)
-- ======================================================
INSERT INTO units (unit_number, address, unit_type, unit_size, status, floor, latest_aircon_service)
VALUES
-- === Floor 1 ===
('A101', '92/1',  'A', 32.5, 'OCCUPIED', 1, '2025-03-10'), -- admin
('A102', '92/2',  'A', 33.0, 'OCCUPIED', 1, '2025-04-01'), -- staff1
('A103', '92/3',  'B', 34.5, 'OCCUPIED', 1, '2025-04-15'), -- staff2
('A104', '92/4',  'B', 35.0, 'AVAILABLE', 1, '2025-05-20'),
('A105', '92/5',  'C', 40.0, 'AVAILABLE', 1, '2025-06-05'),
('A106', '92/6',  'C', 41.0, 'AVAILABLE', 1, '2025-07-01'),
('A107', '92/7',  'A', 32.0, 'RESERVED',  1, '2025-03-01'),
('A108', '92/8',  'B', 36.0, 'RESERVED',  1, '2025-03-25'),
('A109', '92/9',  'C', 45.0, 'RESERVED',  1, '2025-04-20'),
('A110', '92/10', 'A', 31.0, 'OCCUPIED',  1, '2025-04-10'),
('A111', '92/11', 'B', 37.5, 'OCCUPIED',  1, '2025-05-05'),
('A112', '92/12', 'C', 43.0, 'OCCUPIED',  1, '2025-06-15'),
-- === Floor 2 ===
('B201', '92/13', 'A', 33.0, 'AVAILABLE', 2, '2025-02-10'),
('B202', '92/14', 'B', 37.0, 'AVAILABLE', 2, '2025-03-12'),
('B203', '92/15', 'C', 46.0, 'AVAILABLE', 2, '2025-04-10'),
('B204', '92/16', 'A', 31.5, 'AVAILABLE', 2, '2025-05-01'),
('B205', '92/17', 'B', 38.0, 'RESERVED',  2, '2025-06-10'),
('B206', '92/18', 'C', 44.5, 'RESERVED',  2, '2025-07-15'),
('B207', '92/19', 'A', 30.0, 'RESERVED',  2, '2025-08-01'),
('B208', '92/20', 'B', 36.0, 'RESERVED',  2, '2025-09-01'),
('B209', '92/21', 'C', 47.0, 'OCCUPIED',  2, '2025-04-18'),
('B210', '92/22', 'A', 35.0, 'OCCUPIED',  2, '2025-05-10'),
('B211', '92/23', 'B', 42.0, 'OCCUPIED',  2, '2025-06-20'),
('B212', '92/24', 'C', 48.0, 'AVAILABLE', 2, '2025-07-10');

-- ======================================================
-- 👥 Users : 1 Admin + 2 Staff + 9 Tenants
-- ======================================================
INSERT INTO users (first_name, last_name, phone, email, password, role, identification_number, active)
VALUES
    ('Admin',  'Root',   '0800000000', 'admin@apt.com',  crypt('admin',  gen_salt('bf')), 'ADMIN', '1234567890123', true),
    ('Staff',  'One',    '0801111111', 'staff1@apt.com', crypt('staff',  gen_salt('bf')), 'STAFF', '1234567890124', true),
    ('Staff',  'Two',    '0802222222', 'staff2@apt.com', crypt('staff',  gen_salt('bf')), 'STAFF', '1234567890125', true),
    ('Tenant', 'A', '0803333333', 'tenant1@apt.com', crypt('tenant', gen_salt('bf')), 'TENANT', '1234567890126', true),
    ('Tenant', 'B', '0804444444', 'tenant2@apt.com', crypt('tenant', gen_salt('bf')), 'TENANT', '1234567890127', true),
    ('Tenant', 'C', '0805555555', 'tenant3@apt.com', crypt('tenant', gen_salt('bf')), 'TENANT', '1234567890128', false),
    ('Tenant', 'D', '0806666666', 'tenant4@apt.com', crypt('tenant', gen_salt('bf')), 'TENANT', '1234567890129', false),
    ('Tenant', 'E', '0807777777', 'tenant5@apt.com', crypt('tenant', gen_salt('bf')), 'TENANT', '1234567890130', false),
    ('Tenant', 'F', '0808888888', 'tenant6@apt.com', crypt('tenant', gen_salt('bf')), 'TENANT', '1234567890131', false),
    ('Tenant', 'G', '0809999999', 'tenant7@apt.com', crypt('tenant', gen_salt('bf')), 'TENANT', '1234567890132', true),
    ('Tenant', 'H', '0810000001', 'tenant8@apt.com', crypt('tenant', gen_salt('bf')), 'TENANT', '1234567890133', true),
    ('Tenant', 'I', '0810000002', 'tenant9@apt.com', crypt('tenant', gen_salt('bf')), 'TENANT', '1234567890134', true),
    ('Tenant', 'J', '0810000003', 'tenant10@apt.com', crypt('tenant', gen_salt('bf')), 'TENANT', '1234567890135',
     false),
    ('Tenant', 'K', '0810000004', 'tenant11@apt.com', crypt('tenant', gen_salt('bf')), 'USER', '1234567890136', false),
    ('Tenant', 'K', '0810000005', 'tenant12@apt.com', crypt('tenant', gen_salt('bf')), 'USER', '1234567890137', false),
    ('Tenant', 'K', '0810000006', 'tenant13@apt.com', crypt('tenant', gen_salt('bf')), 'USER', '1234567890138', false);

    -- Not active and not signed contract (JUST USER)

-- ======================================================
-- ⚙️ Apartment Config
-- ======================================================
INSERT INTO apartment_configs (electric_price_per_unit, water_price_per_unit, common_fee, internet_price)
VALUES (7.50, 15.00, 1200.00, 500.00);

-- ======================================================
-- 📜 Contracts
-- ======================================================
INSERT INTO contracts (user_id, unit_id, rent_type, rent_amount, water_billing_type, internet, start_date, end_date, status)
VALUES
-- Admin & Staff (OCCUPIED → ACTIVE)
((SELECT id FROM users WHERE email='admin@apt.com'), (SELECT id FROM units WHERE unit_number='A101'), 'MONTHLY', 16000.00, 'PER_UNIT', true, '2025-04-01', '2026-03-31', 'ACTIVE'),
((SELECT id FROM users WHERE email='staff1@apt.com'), (SELECT id FROM units WHERE unit_number='A102'), 'MONTHLY', 12000.00, 'PER_UNIT', true, '2025-05-01', '2026-04-30', 'ACTIVE'),
((SELECT id FROM users WHERE email='staff2@apt.com'), (SELECT id FROM units WHERE unit_number='A103'), 'MONTHLY', 12500.00, 'TIERED', true, '2025-06-01', '2026-05-31', 'ACTIVE'),

-- Tenants ACTIVE
((SELECT id FROM users WHERE email='tenant1@apt.com'), (SELECT id FROM units WHERE unit_number='A110'), 'MONTHLY', 12000.00, 'PER_UNIT', true, '2025-06-01', '2026-05-31', 'ACTIVE'),
((SELECT id FROM users WHERE email='tenant2@apt.com'), (SELECT id FROM units WHERE unit_number='A111'), 'YEARLY', 140000.00, 'FLAT_RATE', false, '2025-01-01', '2025-12-31', 'ACTIVE'),
((SELECT id FROM users WHERE email='tenant7@apt.com'), (SELECT id FROM units WHERE unit_number='A112'), 'MONTHLY', 13200.00, 'PER_UNIT', true, '2025-07-01', '2026-06-30', 'ACTIVE'),
((SELECT id FROM users WHERE email='tenant8@apt.com'), (SELECT id FROM units WHERE unit_number='B209'), 'MONTHLY', 14000.00, 'TIERED', true, '2025-08-01', '2026-07-31', 'ACTIVE'),
((SELECT id FROM users WHERE email='tenant9@apt.com'), (SELECT id FROM units WHERE unit_number='B210'), 'YEARLY', 155000.00, 'PER_UNIT', true, '2025-03-01', '2026-02-28', 'ACTIVE'),
((SELECT id FROM users WHERE email='tenant5@apt.com'), (SELECT id FROM units WHERE unit_number='B211'), 'MONTHLY', 13800.00, 'PER_UNIT', true, '2025-03-01', '2026-02-28', 'ACTIVE'),

-- Tenants RESERVED → SIGNED
((SELECT id FROM users WHERE email='tenant3@apt.com'), (SELECT id FROM units WHERE unit_number='A107'), 'MONTHLY', 12000.00, 'PER_UNIT', true, '2025-10-01', '2026-09-30', 'SIGNED'),
((SELECT id FROM users WHERE email='tenant4@apt.com'), (SELECT id FROM units WHERE unit_number='A108'), 'MONTHLY', 12500.00, 'PER_UNIT', true, '2025-10-01', '2026-09-30', 'SIGNED'),
((SELECT id FROM users WHERE email='tenant6@apt.com'), (SELECT id FROM units WHERE unit_number='A109'), 'YEARLY', 140000.00, 'TIERED', false, '2025-09-01', '2026-08-31', 'SIGNED'),
((SELECT id FROM users WHERE email='tenant2@apt.com'), (SELECT id FROM units WHERE unit_number='B205'), 'MONTHLY', 13000.00, 'PER_UNIT', true, '2025-10-01', '2026-09-30', 'SIGNED'),
((SELECT id FROM users WHERE email='tenant4@apt.com'), (SELECT id FROM units WHERE unit_number='B206'), 'MONTHLY', 13500.00, 'PER_UNIT', true, '2025-10-01', '2026-09-30', 'SIGNED'),
((SELECT id FROM users WHERE email='tenant9@apt.com'), (SELECT id FROM units WHERE unit_number='B207'), 'YEARLY', 160000.00, 'FLAT_RATE', false, '2025-09-01', '2026-08-31', 'SIGNED'),
((SELECT id FROM users WHERE email='tenant10@apt.com'), (SELECT id FROM units WHERE unit_number='B208'), 'MONTHLY', 14500.00, 'PER_UNIT', true, '2025-10-01', '2026-09-30', 'SIGNED');


-- ======================================================
-- 💰 Invoices : only ACTIVE contracts
-- ======================================================
INSERT INTO invoices (contract_id, apartment_config_id, billing_month, electric_usage, water_usage, status, due_date, total_amount, paid_date, created_at, updated_at)
SELECT c.id, ac.id, '2025-09-01', 200, 25, 'PAID', '2025-09-30 23:59:59+07',
       (c.rent_amount/12) + (200*ac.electric_price_per_unit) + (25*ac.water_price_per_unit) + ac.common_fee + ac.internet_price,
       '2025-09-20 10:00:00+07',
       '2025-09-10 00:00:00+07',   -- ✅ created_at ก่อน paid_date
       '2025-09-10 00:00:00+07'
FROM contracts c CROSS JOIN apartment_configs ac
WHERE c.status='ACTIVE';


-- ======================================================
-- 🛠 Maintenances
-- ======================================================
INSERT INTO maintenances (unit_id, title, description, price, priority, maintenance_type, assigned_to, reported_by,
                          status, scheduled_at, estimated_finish_time, started_at)
VALUES ((SELECT id FROM units WHERE unit_number = 'A101'), 'Electrical check', 'Admin requested full wiring check',
        1000.00, 'LOW', 'ELECTRIC', (SELECT id FROM users WHERE email = 'staff1@apt.com'),
        (SELECT id FROM users WHERE email = 'admin@apt.com'), 'SCHEDULED', '2025-10-15 09:00:00+07',
        '2025-10-15 09:30:00+07', NULL),
       ((SELECT id FROM units WHERE unit_number = 'B209'), 'Water leak', 'Tenant reported minor leak', 1500.00,
        'MEDIUM', 'WATER_LEAKAGE', (SELECT id FROM users WHERE email = 'staff2@apt.com'),
        (SELECT id FROM users WHERE email = 'tenant8@apt.com'), 'IN_PROGRESS', '2025-10-14 08:00:00+07',
        '2025-10-14 08:30:00+07', '2025-10-14 08:00:00+07');

-- ======================================================
-- 📦 Supplies
-- ======================================================
INSERT INTO supplies (name, category, quantity, min_stock)
VALUES
    ('Light Bulb', 'ELECTRICAL', 50, 10),
    ('Pipe', 'PLUMBING', 30, 5),
    ('Wrench', 'TOOLS', 20, 5),
    ('Wire', 'ELECTRICAL', 25, 5),
    ('Paint', 'BUILDING', 10, 2);