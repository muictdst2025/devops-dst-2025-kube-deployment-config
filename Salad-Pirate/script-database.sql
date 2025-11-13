CREATE DATABASE saladpirate_db;
CREATE USER saladpirate_user WITH PASSWORD 'saladpirate_pass';
GRANT ALL PRIVILEGES ON DATABASE saladpirate_db TO saladpirate_user;

\c saladpirate_db saladpirate_user

create table if not exists public.users(
	user_id int generated always as identity primary key,
	email varchar(255) not null unique,
	password_hash varchar(255) not null,
	display_name varchar(255) not null,
	created_at timestamptz default now() not null,
	updated_at timestamptz default now() not null
);

insert into users (email,password_hash,display_name) values
(
	'alice@example.com', 'alicethymefield', 'Alice'
),
(
    'yuzuha@example.com', 'ukinamiyuzuha', 'yuzuha'
);

select * from users;

create table if not exists public.categories(
	category_id int generated always as identity primary key,
	user_id int not null references public.users(user_id) on delete cascade,
	category_name varchar(255) not null,
	category_type varchar(15) not null,
	color_hex varchar(7) not null,
	created_at timestamptz default now() not null,

	-- Prevent same category name in the same user
	unique (user_id, category_name),
	constraint uniques_categories_user_pair unique(user_id,category_id)
);

insert into categories (user_id, category_name, category_type, color_hex) values
(
	1,'Food', 'Income','#000000'
),
(
    2,'Game', 'Expense','#000000'
);

select * from categories;create table if not exists public.payment_methods(
	payment_method_id int generated always as identity primary key,
	user_id int not null references public.users(user_id) on delete cascade,
	payment_method_name varchar(255) not null,
	color_hex varchar(7) not null,
	created_at timestamptz default now() not null,

	-- Prevent same payment method name in the same user
	unique (user_id,payment_method_name),
	constraint unique_payment_methods_user_pair unique(user_id, payment_method_id)
);

insert into payment_methods (user_id, payment_method_name, color_hex) values
(
	1,'Cash','#000000'
),
(
    2,'Visa', '#000000'
);

select * from payment_methods;create table if not exists public.wallets(
	wallet_id int generated always as identity primary key,
	user_id int not null references public.users(user_id) on delete cascade,
	wallet_name varchar(255) not null,
	starting_balance numeric(12,2) not null default 0,
	wallet_type varchar(255) not null,
	color_hex varchar(7) not null,
	created_at timestamptz default now() not null,

	-- Prevent same wallet name in the same user
	unique (user_id, wallet_name),
	constraint unique_wallets_user_pair unique(user_id, wallet_id)
);

insert into wallets(user_id, wallet_name, wallet_type, color_hex) values
(
	1,'Wallet_1','Cash', '#000000'
),
(
    2,'first_wallet','Savings', '#000000'
);

select * from wallets;create table if not exists public.transactions(
	transaction_id int generated always as identity primary key,
	user_id int not null references public.users(user_id),

	category_id int not null,
	payment_method_id int not null,
	wallet_id int not null,

	amount numeric(12,2) not null,
	transaction_type varchar(15) not null 
		check(transaction_type in ('Income', 'Expense')),
	

	occured_at timestamptz not null,
	transaction_location varchar(255),
	note varchar(255),

	-- Prevent user use category, payment_method, wallet form other user
	constraint fk_transactions_categories
		foreign key (user_id, category_id)
		references public.categories(user_id, category_id)
		on delete cascade,

	constraint fk_transactions_payment_methods
		foreign key (user_id, payment_method_id)
		references public.payment_methods(user_id, payment_method_id)
		on delete cascade,

	constraint fk_transactions_wallets
		foreign key (user_id, wallet_id)
		references public.wallets(user_id, wallet_id)
		on delete cascade,

	constraint chk_transactions_amount_positive check (amount > 0)
);

insert into transactions(
	user_id, category_id, payment_method_id, wallet_id,
	transaction_type, occured_at, amount
) values
(
	1, 1, 1, 1, 'Income','2025-09-22 00:05:47.391999+07', 50
),
(
    2, 2, 2, 2, 'Income','2025-09-22 00:05:47.391999+07', 200
);

select * from transactions;
