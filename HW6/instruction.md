# Инструкция (хотя по тексту задания она не нужна: достаточно артефактов в системе)

Загружаем данные:

```
mkdir team-36-data
cd team-36-data
wget https://github.com/INikolaR/data_platforms/raw/master/titanic.csv
```

Запускаем gpfdist:

```
gpfdist -p 8084 -d /home/user/team-36-data &
```

Порт 8084 был выбран как один из свободных. Кстати, вроде как через время какие-то процессы gpfdist сами по себе останавливаются, поэтому их надо иногда запускать заново.

Посмотреть список запущенных процессов gpfdist можно:

```
ps aux | grep gpfdist
```

Далее подключаемся к базе:

```
psql -d idp
```

Создаём внешнюю таблицу:

```
CREATE EXTERNAL TABLE team_36_external (
    passengerId INTEGER,
    survived INTEGER,
    pclass INTEGER,
    name TEXT,
    sex TEXT,
    age DOUBLE PRECISION,
    sibSp INTEGER,
    parch INTEGER,
    ticket TEXT,
    fare DOUBLE PRECISION,
    cabin TEXT,
    embarked TEXT
)
LOCATION ('gpfdist://localhost:8084/titanic.csv')
FORMAT 'CSV' (DELIMITER ',' HEADER);
```

Создаём внутреннюю таблицу:

```
CREATE TABLE team_36_internal (
    passengerId INTEGER,
    survived INTEGER,
    pclass INTEGER,
    name TEXT,
    sex TEXT,
    age DOUBLE PRECISION,
    sibSp INTEGER,
    parch INTEGER,
    ticket TEXT,
    fare DOUBLE PRECISION,
    cabin TEXT,
    embarked TEXT
) DISTRIBUTED RANDOMLY;
```

Копируем данные из внешней таблицы во внутреннюю:

```
INSERT INTO team_36_internal SELECT * FROM team_36_external;
```

Проверяем, что всё хорошо:

```
SELECT * FROM team_36_internal LIMIT 5;
SELECT * FROM team_36_external LIMIT 5;
```
