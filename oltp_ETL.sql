--экспортируем данные в CSV файлы
COPY (SELECT * FROM users) TO 'C:/src/Data/users.csv' WITH (FORMAT CSV, HEADER);
COPY (SELECT * FROM clubs) TO 'C:/src/Data/clubs.csv' WITH (FORMAT CSV, HEADER);
COPY (SELECT * FROM addresses) TO 'C:/src/Data/addresses.csv' WITH (FORMAT CSV, HEADER);
COPY (SELECT * FROM tables) TO 'C:/src/Data/tables.csv' WITH (FORMAT CSV, HEADER);
COPY (SELECT * FROM masters) TO 'C:/src/Data/masters.csv' WITH (FORMAT CSV, HEADER);
COPY (SELECT * FROM events) TO 'C:/src/Data/events.csv' WITH (FORMAT CSV, HEADER);
COPY (SELECT * FROM bookings) TO 'C:/src/Data/bookings.csv' WITH (FORMAT CSV, HEADER);
COPY (SELECT * FROM reviews) TO 'C:/src/Data/reviews.csv' WITH (FORMAT CSV, HEADER);
COPY (SELECT * FROM event_history) TO 'C:/src/Data/event_history.csv' WITH (FORMAT CSV, HEADER);
COPY (SELECT * FROM event_registrations) TO 'C:/src/Data/event_registrations.csv' WITH (FORMAT CSV, HEADER);



