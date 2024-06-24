-- Функция добавления пользователя

CREATE OR REPLACE FUNCTION add_user(
  p_name VARCHAR,
  p_email VARCHAR,
  p_city VARCHAR
) RETURNS UUID AS $$
DECLARE
  v_uid UUID := gen_random_uuid();
BEGIN
  -- Проверка уникальности email
  IF EXISTS (SELECT 1 FROM users WHERE email = p_email) THEN
    RAISE EXCEPTION 'Пользователь с email % уже существует', p_email;
  END IF;

  INSERT INTO users (uid, name, email, city, created_at)
  VALUES (v_uid, p_name, p_email, p_city, NOW());
  RETURN v_uid;
END;
$$ LANGUAGE plpgsql;

--Функция добавления клуба

CREATE OR REPLACE FUNCTION add_club(
  p_name VARCHAR,
  p_country VARCHAR,
  p_city VARCHAR,
  p_address_id UUID,
  p_default_master VARCHAR,
  p_working_hours VARCHAR
) RETURNS UUID AS $$
DECLARE
  v_uid UUID := gen_random_uuid();
BEGIN
  INSERT INTO clubs (uid, name, country, city, address_id, default_master, working_hours, created_at)
  VALUES (v_uid, p_name, p_country, p_city, p_address_id, p_default_master, p_working_hours, NOW());
  RETURN v_uid;
END;
$$ LANGUAGE plpgsql;


--Функция добавления стола в клуб

CREATE OR REPLACE FUNCTION add_table(
  p_club_id UUID,
  p_name VARCHAR,
  p_capacity INT
) RETURNS UUID AS $$
DECLARE
  v_uid UUID := gen_random_uuid();
BEGIN
  -- Проверка существования клуба
  IF NOT EXISTS (SELECT 1 FROM clubs WHERE uid = p_club_id) THEN
    RAISE EXCEPTION 'Клуб с ID % не существует', p_club_id;
  END IF;

  INSERT INTO tables (uid, club_id, name, capacity, created_at)
  VALUES (v_uid, p_club_id, p_name, p_capacity, NOW());
  RETURN v_uid;
END;
$$ LANGUAGE plpgsql;


--Функция для создания события

CREATE OR REPLACE FUNCTION create_event(
  p_club_id UUID,
  p_master_id UUID,
  p_user_id UUID,
  p_name VARCHAR,
  p_description TEXT,
  p_date_start TIMESTAMP,
  p_date_end TIMESTAMP,
  p_table_id UUID,
  p_num_people INT,
  p_is_club_event BOOLEAN
) RETURNS UUID AS $$
DECLARE
  v_uid UUID := gen_random_uuid();
  v_table_capacity INT;
BEGIN
  -- Валидация входных данных
  IF p_date_start >= p_date_end THEN
    RAISE EXCEPTION 'Дата начала события должна быть раньше даты окончания';
  END IF;

  IF p_num_people <= 0 THEN
    RAISE EXCEPTION 'Количество людей должно быть больше нуля';
  END IF;

  -- Проверка вместимости стола
  SELECT capacity INTO v_table_capacity
  FROM tables
  WHERE uid = p_table_id;

  IF p_num_people > v_table_capacity THEN
    RAISE EXCEPTION 'Количество людей (%s) превышает вместимость стола (%s)', p_num_people, v_table_capacity;
  END IF;

  -- Проверка, что стол доступен в заданное время
  PERFORM 1 FROM events
  WHERE table_id = p_table_id
    AND (p_date_start, p_date_end) OVERLAPS (date_start, date_end)
    AND status != 'canceled';
  IF FOUND THEN
    RAISE EXCEPTION 'Стол занят в указанное время';
  END IF;

  -- Создание записи о событии
  INSERT INTO events (uid, club_id, master_id, user_id, name, description, date_start, date_end, table_id, num_people, is_club_event, status, created_at)
  VALUES (v_uid, p_club_id, p_master_id, p_user_id, p_name, p_description, p_date_start, p_date_end, p_table_id, p_num_people, p_is_club_event, 'created', NOW());

  -- Обновление истории событий
  PERFORM add_event_history(v_uid, p_club_id, p_master_id, p_user_id, p_name, p_description, p_date_start, p_date_end, p_table_id, p_num_people, 'created');
  
  RETURN v_uid;
END;
$$ LANGUAGE plpgsql;


--Функция для редактирования события

CREATE OR REPLACE FUNCTION edit_event(
  p_event_id UUID,
  p_club_id UUID,
  p_master_id UUID,
  p_user_id UUID,
  p_name VARCHAR,
  p_description TEXT,
  p_date_start TIMESTAMP,
  p_date_end TIMESTAMP,
  p_table_id UUID,
  p_num_people INT,
  p_is_club_event BOOLEAN
) RETURNS VOID AS $$
DECLARE
  v_table_capacity INT;
BEGIN
  -- Валидация входных данных
  IF p_date_start >= p_date_end THEN
    RAISE EXCEPTION 'Дата начала события должна быть раньше даты окончания';
  END IF;

  IF p_num_people <= 0 THEN
    RAISE EXCEPTION 'Количество людей должно быть больше нуля';
  END IF;

  -- Проверка вместимости стола
  SELECT capacity INTO v_table_capacity
  FROM tables
  WHERE uid = p_table_id;

  IF p_num_people > v_table_capacity THEN
    RAISE EXCEPTION 'Количество людей (%s) превышает вместимость стола (%s)', p_num_people, v_table_capacity;
  END IF;

  -- Проверка, что стол доступен в заданное время
  PERFORM 1 FROM events
  WHERE table_id = p_table_id
    AND (p_date_start, p_date_end) OVERLAPS (date_start, date_end)
    AND uid != p_event_id
    AND status != 'canceled';
  IF FOUND THEN
    RAISE EXCEPTION 'Стол занят в указанное время';
  END IF;

  -- Обновление записи о событии
  UPDATE events
  SET club_id = p_club_id,
      master_id = p_master_id,
      user_id = p_user_id,
      name = p_name,
      description = p_description,
      date_start = p_date_start,
      date_end = p_date_end,
      table_id = p_table_id,
      num_people = p_num_people,
      is_club_event = p_is_club_event,
      status = 'updated'
  WHERE uid = p_event_id;

  -- Обновление истории событий
  PERFORM add_event_history(p_event_id, p_club_id, p_master_id, p_user_id, p_name, p_description, p_date_start, p_date_end, p_table_id, p_num_people, 'updated');
END;
$$ LANGUAGE plpgsql;


--Функция для добавления пользователей в события

CREATE OR REPLACE FUNCTION add_user_to_event(
  p_user_id UUID,
  p_event_id UUID
) RETURNS UUID AS $$
DECLARE
  v_uid UUID := gen_random_uuid();
  v_table_id UUID;
  v_table_capacity INT;
  v_registered_count INT;
BEGIN
  -- Проверка существования пользователя
  IF NOT EXISTS (SELECT 1 FROM users WHERE uid = p_user_id) THEN
    RAISE EXCEPTION 'Пользователь с ID % не существует', p_user_id;
  END IF;

  -- Проверка существования события
  IF NOT EXISTS (SELECT 1 FROM events WHERE uid = p_event_id) THEN
    RAISE EXCEPTION 'Событие с ID % не существует', p_event_id;
  END IF;

  -- Проверка, что пользователь уже зарегистрирован на это событие
  IF EXISTS (SELECT 1 FROM event_registrations WHERE user_id = p_user_id AND event_id = p_event_id) THEN
    RAISE EXCEPTION 'Пользователь с ID % уже зарегистрирован на событие с ID %', p_user_id, p_event_id;
  END IF;

  -- Получение ID стола и его вместимости
  SELECT table_id INTO v_table_id FROM events WHERE uid = p_event_id;
  SELECT capacity INTO v_table_capacity FROM tables WHERE uid = v_table_id;

  -- Подсчет текущего количества зарегистрированных пользователей на событие
  SELECT COUNT(*) INTO v_registered_count FROM event_registrations WHERE event_id = p_event_id;

  -- Проверка, что вместимость стола не превышена
  IF v_registered_count >= v_table_capacity THEN
    RAISE EXCEPTION 'Вместимость стола (%s) превышена для события с ID %', v_table_capacity, p_event_id;
  END IF;

  -- Добавление пользователя в событие
  INSERT INTO event_registrations (uid, user_id, event_id, status)
  VALUES (v_uid, p_user_id, p_event_id, 'registered');
  RETURN v_uid;
END;
$$ LANGUAGE plpgsql;


-- Функция для удаления события

CREATE OR REPLACE FUNCTION delete_event(
  p_event_id UUID
) RETURNS VOID AS $$
BEGIN
  -- Обновление истории событий перед удалением
  PERFORM add_event_history(p_event_id, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'deleted');

  -- Удаление события
  DELETE FROM events WHERE uid = p_event_id;
  DELETE FROM event_history WHERE event_id = p_event_id;
  DELETE FROM event_registrations WHERE event_id = p_event_id;
END;
$$ LANGUAGE plpgsql;


-- Функция для бронирования стола

CREATE OR REPLACE FUNCTION book_table(
  p_user_id UUID,
  p_event_id UUID,
  p_table_id UUID,
  p_booking_date TIMESTAMP,
  p_status VARCHAR
) RETURNS UUID AS $$
DECLARE
  v_uid UUID := gen_random_uuid();
BEGIN
  -- Проверка существования пользователя
  IF NOT EXISTS (SELECT 1 FROM users WHERE uid = p_user_id) THEN
    RAISE EXCEPTION 'Пользователь с ID % не существует', p_user_id;
  END IF;

  -- Проверка существования события
  IF NOT EXISTS (SELECT 1 FROM events WHERE uid = p_event_id) THEN
    RAISE EXCEPTION 'Событие с ID % не существует', p_event_id;
  END IF;

  -- Проверка существования стола
  IF NOT EXISTS (SELECT 1 FROM tables WHERE uid = p_table_id) THEN
    RAISE EXCEPTION 'Стол с ID % не существует', p_table_id;
  END IF;

  -- Создание бронирования
  INSERT INTO bookings (uid, user_id, event_id, table_id, booking_date, status, created_at)
  VALUES (v_uid, p_user_id, p_event_id, p_table_id, p_booking_date, p_status, NOW());
  RETURN v_uid;
END;
$$ LANGUAGE plpgsql;


-- Функция для отмены бронирования стола

CREATE OR REPLACE FUNCTION cancel_booking(
  p_booking_id UUID
) RETURNS VOID AS $$
BEGIN
  UPDATE bookings
  SET status = 'canceled'
  WHERE uid = p_booking_id;
END;
$$ LANGUAGE plpgsql;


-- Функция для добавления отзыва

CREATE OR REPLACE FUNCTION add_review(
  p_user_id UUID,
  p_entity_id UUID,
  p_entity_type VARCHAR,
  p_event_id UUID,
  p_rating INT,
  p_comment TEXT
) RETURNS UUID AS $$
DECLARE
  v_uid UUID := gen_random_uuid();
BEGIN
  -- Проверка существования пользователя
  IF NOT EXISTS (SELECT 1 FROM users WHERE uid = p_user_id) THEN
    RAISE EXCEPTION 'Пользователь с ID % не существует', p_user_id;
  END IF;

  -- Проверка существования события
  IF NOT EXISTS (SELECT 1 FROM events WHERE uid = p_event_id) THEN
    RAISE EXCEPTION 'Событие с ID % не существует', p_event_id;
  END IF;

  -- Создание отзыва
  INSERT INTO reviews (uid, user_id, entity_id, entity_type, event_id, rating, comment, created_at)
  VALUES (v_uid, p_user_id, p_entity_id, p_entity_type, p_event_id, p_rating, p_comment, NOW());
  RETURN v_uid;
END;
$$ LANGUAGE plpgsql;


-- Функция для обновления данных пользователя

CREATE OR REPLACE FUNCTION update_user(
  p_uid UUID,
  p_name VARCHAR,
  p_email VARCHAR,
  p_city VARCHAR
) RETURNS VOID AS $$
BEGIN
  -- Проверка существования пользователя
  IF NOT EXISTS (SELECT 1 FROM users WHERE uid = p_uid) THEN
    RAISE EXCEPTION 'Пользователь с ID % не существует', p_uid;
  END IF;

  -- Обновление данных пользователя
  UPDATE users
  SET name = p_name, email = p_email, city = p_city
  WHERE uid = p_uid;
END;
$$ LANGUAGE plpgsql;


--Функция для обновления данных клуба

CREATE OR REPLACE FUNCTION update_club(
  p_uid UUID,
  p_name VARCHAR,
  p_country VARCHAR,
  p_city VARCHAR,
  p_address_id UUID,
  p_default_master VARCHAR,
  p_working_hours VARCHAR
) RETURNS VOID AS $$
BEGIN
  -- Проверка существования клуба
  IF NOT EXISTS (SELECT 1 FROM clubs WHERE uid = p_uid) THEN
    RAISE EXCEPTION 'Клуб с ID % не существует', p_uid;
  END IF;

  -- Обновление данных клуба
  UPDATE clubs
  SET name = p_name, country = p_country, city = p_city, address_id = p_address_id, default_master = p_default_master, working_hours = p_working_hours
  WHERE uid = p_uid;
END;
$$ LANGUAGE plpgsql;


--Функция для отмены регистрации пользователя на событие

CREATE OR REPLACE FUNCTION cancel_user_registration(
  p_user_id UUID,
  p_event_id UUID
) RETURNS VOID AS $$
BEGIN
  DELETE FROM event_registrations
  WHERE user_id = p_user_id AND event_id = p_event_id;
END;
$$ LANGUAGE plpgsql;


-- Функция добавления мастера

CREATE OR REPLACE FUNCTION add_master(
  p_user_id UUID
) RETURNS UUID AS $$
DECLARE
  v_uid UUID := gen_random_uuid();
BEGIN
  -- Проверка существования пользователя
  IF NOT EXISTS (SELECT 1 FROM users WHERE uid = p_user_id) THEN
    RAISE EXCEPTION 'Пользователь с ID % не существует', p_user_id;
  END IF;

  INSERT INTO masters (uid, user_id, created_at)
  VALUES (v_uid, p_user_id, NOW());
  RETURN v_uid;
END;
$$ LANGUAGE plpgsql;


-- Функция добавления связи мастер-клуб

CREATE OR REPLACE FUNCTION add_master_club_relationship(
  p_master_id UUID,
  p_club_id UUID
) RETURNS UUID AS $$
DECLARE
  v_uid UUID := gen_random_uuid();
BEGIN
  -- Проверка существования мастера
  IF NOT EXISTS (SELECT 1 FROM masters WHERE uid = p_master_id) THEN
    RAISE EXCEPTION 'Мастер с ID % не существует', p_master_id;
  END IF;

  -- Проверка существования клуба
  IF NOT EXISTS (SELECT 1 FROM clubs WHERE uid = p_club_id) THEN
    RAISE EXCEPTION 'Клуб с ID % не существует', p_club_id;
  END IF;

  INSERT INTO master_club (uid, master_id, club_id, created_at)
  VALUES (v_uid, p_master_id, p_club_id, NOW());
  RETURN v_uid;
END;
$$ LANGUAGE plpgsql;


-- Функция удаления связи мастер-клуб

CREATE OR REPLACE FUNCTION remove_master_club_relationship(
  p_master_id UUID,
  p_club_id UUID
) RETURNS VOID AS $$
BEGIN
  DELETE FROM master_club
  WHERE master_id = p_master_id AND club_id = p_club_id;
END;
$$ LANGUAGE plpgsql;


-- Функция для добавления записей в историю событий (event_history)

CREATE OR REPLACE FUNCTION add_event_history(
  p_event_id UUID,
  p_club_id UUID,
  p_master_id UUID,
  p_user_id UUID,
  p_name VARCHAR,
  p_description TEXT,
  p_date_start TIMESTAMP,
  p_date_end TIMESTAMP,
  p_table_id UUID,
  p_num_people INT,
  p_status VARCHAR
) RETURNS UUID AS $$
DECLARE
  v_uid UUID := gen_random_uuid();
BEGIN
  INSERT INTO event_history (
    uid, event_id, club_id, master_id, user_id, name, description, date_start, date_end, table_id, num_people, status, created_at
  )
  VALUES (
    v_uid, p_event_id, p_club_id, p_master_id, p_user_id, p_name, p_description, p_date_start, p_date_end, p_table_id, p_num_people, p_status, NOW()
  );
  RETURN v_uid;
END;
$$ LANGUAGE plpgsql;


-- Триггер для автоматического добавления записей в историю событий при завершении событий

CREATE OR REPLACE FUNCTION trigger_add_event_to_history()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' THEN
    INSERT INTO event_history (
      uid, event_id, club_id, master_id, user_id, name, description, date_start, date_end, table_id, num_people, status, created_at
    )
    VALUES (
      gen_random_uuid(), NEW.uid, NEW.club_id, NEW.master_id, NEW.user_id, NEW.name, NEW.description, NEW.date_start, NEW.date_end, NEW.table_id, NEW.num_people, NEW.status, NOW()
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Создание триггера

CREATE TRIGGER after_event_update
AFTER UPDATE ON events
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'completed')
EXECUTE FUNCTION trigger_add_event_to_history();

