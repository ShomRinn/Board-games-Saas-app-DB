	-- Addresses table
	CREATE TABLE addresses (
	  id UUID PRIMARY KEY,
	  address VARCHAR(255) NOT NULL,
	  latitude FLOAT,
	  longitude FLOAT,
	  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);


	-- Users table
	CREATE TABLE users (
	  uid UUID PRIMARY KEY,
	  name VARCHAR(255) NOT NULL,
	  email VARCHAR(255) NOT NULL,
	  city VARCHAR(255),
	  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);


	-- Clubs table
	CREATE TABLE clubs (
	  uid UUID PRIMARY KEY,
	  name VARCHAR(255) NOT NULL,
	  country VARCHAR(255),
	  city VARCHAR(255),
	  address_id UUID REFERENCES addresses(id),
	  default_master VARCHAR(255),
	  working_hours VARCHAR(255),
	  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);


	-- Tags table
	CREATE TABLE tags (
	  id UUID PRIMARY KEY,
	  entity_id UUID NOT NULL,
	  entity_type VARCHAR(50) NOT NULL,
	  tag VARCHAR(255) NOT NULL,
	  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

	-- Ratings table
	CREATE TABLE ratings (
	  id UUID PRIMARY KEY,
	  entity_id UUID NOT NULL,
	  entity_type VARCHAR(50) NOT NULL,
	  rating FLOAT NOT NULL,
	  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

	-- Socials table
	CREATE TABLE socials (
	  id UUID PRIMARY KEY,
	  entity_id UUID NOT NULL,
	  entity_type VARCHAR(50) NOT NULL,
	  social_network VARCHAR(255) NOT NULL,
	  social_link VARCHAR(255) NOT NULL
	);

	-- Descriptions table
	CREATE TABLE descriptions (
	  id UUID PRIMARY KEY,
	  entity_id UUID NOT NULL,
	  entity_type VARCHAR(50) NOT NULL,
	  description TEXT NOT NULL,
	  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

	-- Tables table
	CREATE TABLE tables (
	  uid UUID PRIMARY KEY,
	  club_id UUID REFERENCES clubs(uid),
	  name VARCHAR(255) NOT NULL,
	  capacity INT NOT NULL,
	  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);


	-- Masters table
	CREATE TABLE masters (
	  uid UUID PRIMARY KEY,
	  user_id UUID REFERENCES users(uid),
	  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);


	-- Master-Club Relationship table
	CREATE TABLE master_club (
	  uid UUID PRIMARY KEY,
	  master_id UUID REFERENCES masters(uid),
	  club_id UUID REFERENCES clubs(uid),
	  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

	-- Events table
	CREATE TABLE events (
	  uid UUID PRIMARY KEY,
	  club_id UUID REFERENCES clubs(uid),
	  master_id UUID REFERENCES masters(uid),
	  user_id UUID REFERENCES users(uid),
	  name VARCHAR(255) NOT NULL,
	  description TEXT NOT NULL,
	  date_start TIMESTAMP NOT NULL,
	  date_end TIMESTAMP NOT NULL,
	  table_id UUID REFERENCES tables(uid),
	  num_people INT NOT NULL,
	  is_club_event BOOLEAN,
	  status VARCHAR(50),
	  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);


	-- Bookings table
	CREATE TABLE bookings (
	  uid UUID PRIMARY KEY,
	  user_id UUID REFERENCES users(uid),
	  event_id UUID REFERENCES events(uid),
	  table_id UUID REFERENCES tables(uid),
	  booking_date TIMESTAMP NOT NULL,
	  status VARCHAR(50) NOT NULL,
	  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

	-- Reviews table
	CREATE TABLE reviews (
	  uid UUID PRIMARY KEY,
	  user_id UUID REFERENCES users(uid),
	  entity_id UUID NOT NULL,
	  entity_type VARCHAR(50) NOT NULL,
	  event_id UUID REFERENCES events(uid),
	  rating INT NOT NULL,
	  comment TEXT,
	  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);


	-- Event History table
	CREATE TABLE event_history (
	  uid UUID PRIMARY KEY,
	  event_id UUID REFERENCES events(uid),
	  club_id UUID REFERENCES clubs(uid),
	  master_id UUID REFERENCES masters(uid),
	  user_id UUID REFERENCES users(uid),
	  name VARCHAR(255) NOT NULL,
	  description TEXT NOT NULL,
	  date_start TIMESTAMP NOT NULL,
	  date_end TIMESTAMP NOT NULL,
	  table_id UUID REFERENCES tables(uid),
	  num_people INT NOT NULL,
	  status VARCHAR(50) NOT NULL,
	  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

	-- Event Registrations table
	CREATE TABLE event_registrations (
	  uid UUID PRIMARY KEY,
	  user_id UUID REFERENCES users(uid),
	  event_id UUID REFERENCES events(uid),
	  status VARCHAR(50) NOT NULL,
	  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);


	-- Indexes
	CREATE INDEX idx_users_email ON users(email);
	CREATE INDEX idx_clubs_name ON clubs(name);
	CREATE INDEX idx_tags_entity ON tags(entity_id, entity_type);
	CREATE INDEX idx_ratings_entity ON ratings(entity_id, entity_type);
	CREATE INDEX idx_socials_entity ON socials(entity_id, entity_type);
	CREATE INDEX idx_descriptions_entity ON descriptions(entity_id, entity_type);
	CREATE INDEX idx_tables_club ON tables(club_id);
	CREATE INDEX idx_masters_user ON masters(user_id);
	CREATE INDEX idx_master_club ON master_club(master_id, club_id);
	CREATE INDEX idx_events_club ON events(club_id);
	CREATE INDEX idx_events_user ON events(user_id);
	CREATE INDEX idx_bookings_user ON bookings(user_id);
	CREATE INDEX idx_bookings_event ON bookings(event_id);
	CREATE INDEX idx_reviews_entity ON reviews(entity_id, entity_type);
	CREATE INDEX idx_event_history_event ON event_history(event_id);
	CREATE INDEX idx_event_registrations_user ON event_registrations(user_id);
	
	-- Addresses table
COPY addresses (id, address, latitude, longitude, created_at)
FROM 'C:/src/Data/addresses.csv' DELIMITER ',' CSV HEADER;

-- Users table
COPY users (uid, name, email, city, created_at)
FROM 'C:/src/Data/users.csv' DELIMITER ',' CSV HEADER;

-- Clubs table
COPY clubs (uid, name, country, city, address_id, default_master, working_hours, created_at)
FROM 'C:/src/Data/clubs.csv' DELIMITER ',' CSV HEADER;

-- Tables table
COPY tables (uid, club_id, name, capacity, created_at)
FROM 'C:/src/Data/tables.csv' DELIMITER ',' CSV HEADER;

-- Masters table
COPY masters (uid, user_id, created_at)
FROM 'C:/src/Data/masters.csv' DELIMITER ',' CSV HEADER;

-- Events table
COPY events (uid, club_id, master_id, user_id, name, description, date_start, date_end, table_id, num_people, is_club_event, status, created_at)
FROM 'C:/src/Data/events.csv' DELIMITER ',' CSV HEADER;

-- Reviews table
COPY reviews (uid, user_id, entity_id, entity_type, event_id, rating, comment, created_at)
FROM 'C:/src/Data/reviews.csv' DELIMITER ',' CSV HEADER;

-- Event Registrations table
COPY event_registrations (uid, user_id, event_id, status, created_at)
FROM 'C:/src/Data/event_registrations.csv' DELIMITER ',' CSV HEADER;

-- Bookings table
COPY bookings (uid, user_id, event_id, table_id, booking_date, status, created_at)
FROM 'C:/src/Data/bookings.csv' DELIMITER ',' CSV HEADER;


