--Очистка
TRUNCATE TABLE dim_users;
TRUNCATE TABLE dim_clubs;
TRUNCATE TABLE dim_addresses;
TRUNCATE TABLE dim_tables;
TRUNCATE TABLE dim_masters;
TRUNCATE TABLE fact_events;
TRUNCATE TABLE fact_bookings;
TRUNCATE TABLE fact_reviews;
TRUNCATE TABLE fact_event_history;
TRUNCATE TABLE fact_event_registrations;

-- Импорт данных в таблицы OLAP базы данных
COPY dim_users (user_id, name, email, city, created_at) FROM 'C:/src/Data/users.csv' DELIMITER ',' CSV HEADER;
COPY dim_clubs (club_id, name, country, city, address_id, default_master, working_hours, created_at) FROM 'C:/src/Data/clubs.csv' DELIMITER ',' CSV HEADER;
COPY dim_addresses (address_id, address, latitude, longitude, created_at) FROM 'C:/src/Data/addresses.csv' DELIMITER ',' CSV HEADER;
COPY dim_tables (table_id, club_id, name, capacity, created_at) FROM 'C:/src/Data/tables.csv' DELIMITER ',' CSV HEADER;
COPY dim_masters (master_id, user_id, created_at) FROM 'C:/src/Data/masters.csv' DELIMITER ',' CSV HEADER;
COPY fact_events (event_id, club_id, master_id, user_id, name, description, date_start, date_end, table_id, num_people, is_club_event, status, created_at) FROM 'C:/src/Data/events.csv' DELIMITER ',' CSV HEADER;
COPY fact_reviews (review_id, user_id, entity_id, entity_type, event_id, rating, comment, created_at) FROM 'C:/src/Data/reviews.csv' DELIMITER ',' CSV HEADER;
COPY fact_event_history (event_history_id, event_id, club_id, master_id, user_id, name, description, date_start, date_end, table_id, num_people, status, created_at) FROM 'C:/src/Data/event_history.csv' DELIMITER ',' CSV HEADER;
COPY fact_event_registrations (uid, user_id, event_id, status, created_at)
FROM 'C:/src/Data/event_registrations.csv' DELIMITER ',' CSV HEADER;

SELECT * FROM fact_event_history;
