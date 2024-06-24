-- Dimension Tables
CREATE TABLE dim_users (
  user_id UUID PRIMARY KEY,
  name VARCHAR(255),
  email VARCHAR(255),
  city VARCHAR(255),
  created_at TIMESTAMP
);

CREATE TABLE dim_clubs (
  club_id UUID PRIMARY KEY,
  name VARCHAR(255),
  country VARCHAR(255),
  city VARCHAR(255),
  address_id UUID,
  default_master VARCHAR(255),
  working_hours VARCHAR(255),
  created_at TIMESTAMP
);

CREATE TABLE dim_addresses (
  address_id UUID PRIMARY KEY,
  address VARCHAR(255),
  latitude FLOAT,
  longitude FLOAT,
  created_at TIMESTAMP
);

CREATE TABLE dim_tables (
  table_id UUID PRIMARY KEY,
  club_id UUID,
  name VARCHAR(255),
  capacity INT,
  created_at TIMESTAMP
);

CREATE TABLE dim_masters (
  master_id UUID PRIMARY KEY,
  user_id UUID,
  created_at TIMESTAMP
);

-- Fact Tables
CREATE TABLE fact_events (
  event_id UUID PRIMARY KEY,
  club_id UUID,
  master_id UUID,
  user_id UUID,
  name VARCHAR(255),
  description TEXT,
  date_start TIMESTAMP,
  date_end TIMESTAMP,
  table_id UUID,
  num_people INT,
  is_club_event BOOLEAN,
  status VARCHAR(50),
  created_at TIMESTAMP
);


CREATE TABLE fact_bookings (
  booking_id UUID PRIMARY KEY,
  user_id UUID,
  event_id UUID,
  table_id UUID,
  booking_date TIMESTAMP,
  status VARCHAR(50),
  created_at TIMESTAMP
);

CREATE TABLE fact_reviews (
  review_id UUID PRIMARY KEY,
  user_id UUID,
  entity_id UUID,
  entity_type VARCHAR(50),
  event_id UUID,
  rating INT,
  comment TEXT,
  created_at TIMESTAMP
);

CREATE TABLE fact_event_history (
  event_history_id UUID PRIMARY KEY,
  event_id UUID,
  club_id UUID,
  master_id UUID,
  user_id UUID,
  name VARCHAR(255),
  description TEXT,
  date_start TIMESTAMP,
  date_end TIMESTAMP,
  table_id UUID,
  num_people INT,
  status VARCHAR(50),
  created_at TIMESTAMP
);

CREATE TABLE fact_event_registrations (
  uid UUID PRIMARY KEY,
  user_id UUID,
  event_id UUID,
  status VARCHAR(50),
  created_at TIMESTAMP
);