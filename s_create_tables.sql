CREATE SCHEMA IF NOT EXISTS supermarket DEFAULT CHARACTER SET cp1251;
USE supermarket;

CREATE TABLE IF NOT EXISTS manufacturers (
    m_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
    m_name VARCHAR(50) NOT NULL,
    m_country VARCHAR(30) NOT NULL,
    m_city VARCHAR(100) NOT NULL,
    m_address VARCHAR(100) NOT NULL,
    m_phone_number VARCHAR(15) NOT NULL,
    m_email VARCHAR(255),
    UNIQUE INDEX m_name_UNIQUE (m_name),
    UNIQUE INDEX m_email_UNIQUE (m_email)
);

CREATE TABLE IF NOT EXISTS departments (
    d_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
    d_name VARCHAR(50) NOT NULL,
    d_shelving_type ENUM('відкриті', 'закриті', 'з підігрівом', 'з охолодженням') NOT NULL,
    UNIQUE INDEX d_name_UNIQUE (d_name)
);

CREATE TABLE IF NOT EXISTS discount_cards (
    dc_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
    dc_client_name VARCHAR(100) NOT NULL,
    dc_percentage DECIMAL(5 , 1 ) NOT NULL CHECK (dc_percentage BETWEEN 0 AND 100)
);

CREATE TABLE IF NOT EXISTS workers (
    w_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
    w_name VARCHAR(100) NOT NULL,
    w_employment_date DATE NOT NULL CHECK (w_employment_date BETWEEN '2010-07-19' AND NOW()),
    w_firing_date DATE,
    w_birth_date DATE NOT NULL CHECK (YEAR(NOW()) - YEAR(w_birth_date) < 60),
    w_job ENUM('генеральний директор', 'фінансовий директор', 'бухгалтер', 'юрист', 'менеджер по персоналу', 'менеджер закупівлі', 'адміністратор торгового залу', 'промоутер', 'мерчендайзер', 'копірайтер', 'касир', 'охоронець', 'вантажник', 'прибиральник') NOT NULL,
    w_education ENUM('середня спеціальна', 'незакінчена вища', 'вища'),
    w_salary DECIMAL(9 , 2 ) NOT NULL DEFAULT 3200,
    w_d_id INT,
    FOREIGN KEY (w_d_id)
        REFERENCES departments (d_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS invoice (
    i_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
    i_date_time DATETIME NOT NULL CHECK (i_date_time BETWEEN '2010-07-19' AND NOW()),
    i_w_id INT NOT NULL,
    FOREIGN KEY (i_w_id)
        REFERENCES workers (w_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS goods (
    g_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
    g_name VARCHAR(100) NOT NULL,
    g_barcode VARCHAR(13) NOT NULL,
    g_category VARCHAR(30) NOT NULL,
    g_unit_of_measurement VARCHAR(10) NOT NULL,
    g_retail_price DECIMAL(9 , 2 ) NOT NULL CHECK (g_retail_price > 0),
    g_d_id INT NOT NULL,
    g_m_id INT NOT NULL,
    FOREIGN KEY (g_d_id)
        REFERENCES departments (d_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (g_m_id)
        REFERENCES manufacturers (m_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS supplies (
    s_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
    s_units_amount INT NOT NULL DEFAULT 1 CHECK (s_units_amount > 0),
    s_purchase_price DECIMAL(9 , 2 ) NOT NULL CHECK (s_purchase_price > 0),
    s_expiration_date DATE,
    s_i_id INT NOT NULL,
    s_g_id INT NOT NULL,
    FOREIGN KEY (s_i_id)
        REFERENCES invoice (i_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (s_g_id)
        REFERENCES goods (g_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS transactions (
    t_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
    t_date_time DATETIME NOT NULL CHECK (t_date_time BETWEEN '2010-07-19' AND NOW()),
    t_dc_id INT,
    t_w_id INT NOT NULL,
    FOREIGN KEY (t_dc_id)
        REFERENCES discount_cards (dc_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (t_w_id)
        REFERENCES workers (w_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS selling (
    sel_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
    sel_units_amount INT NOT NULL DEFAULT 1 CHECK (sel_units_amount > 0),
    sel_t_id INT NOT NULL,
    sel_g_id INT NOT NULL,
    FOREIGN KEY (sel_t_id)
        REFERENCES transactions (t_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (sel_g_id)
        REFERENCES goods (g_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);