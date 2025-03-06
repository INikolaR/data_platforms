# Инструкция

Входные данные:

```
${team} - пользователь с правами sudoers
${team-password} - пароль пользователя ${team}
${hadoop-password} - пароль пользователя hadoop
${jn} - имя хоста джамп ноды
${nn} - имя хоста нейм ноды
${dn-00} и ${dn-01} - имена хостов 0 и 1 датанод соответственно
${jn-ip}, ${nn-ip}, ${dn-00-ip} и ${dn-01-ip} - ip-адреса всех этих хостов в локальной сети соответственно
```

От имени \${team}@\${nn} установим postgres:

```
sudo apt install postgresql # (при необходимости ввести пароль ${team-password})
```

Переключимся на пользователя postgres и создадим базу данных:

```
sudo -i -u postgres # (при необходимости ввести пароль ${team-password})
psql
CREATE DATABASE metastore;
```

Также создадим пользователя hive (внутри СУБД) с паролем ${hive-password} (придумать надёжный):

```
CREATE USER hive with password ${hive-password}
```

Даём этому пользователю все привилегии и передаём ему во владение базу данных, после чего выходим из psql:

```
GRANT ALL PRIVILEGES ON DATABASE "metastore" to hive;
ALTER DATABASE "metastore" OWNER TO hive;
\q
```

Возвращаемся с пользователя postgres на ${team}:

```
exit
```

Отредакируем конфиг postgres (вместо ${postgres-version} вставить версию postgres, например, 16):

```
sudo nano /etc/postgresql/${postgres-version}/main/postgresql.conf
```

Добавим в начало секции # CONNECTIONS AND AUTHENTICATION строку:

```
listen_addresses = '${nn}'
```

(где ${nn} - имя хоста нейм ноды).

Отредакируем конфиг postgres (вместо ${postgres1-version} вставить версию postgres, например, 16):

```
sudo nano /etc/postgresql/${postgres-version}/main/pg_hba.conf
```

В секцию # IPv4 local connections добавляем строки:

```
host metastore hive 192.168.1.1/32 password
host metastore hive ${jn-ip}/32 password
```

Перезапускаем postgresql:

```
sudo systemctl restart postgresql
```

И возвращаемся на джамп ноду:

```
exit
```

На джамп-ноде устанавливаем клиент postgresql:

```
sudo apt install postgresql-client-${postgres-version}
```

(где ${postgres-version} - версия postgres из команд выше).

Можно проверить работоспособность psql:

```
psql -h ${nn} -p 5432 -U hive -W -d metastore
```

Скачаем hive. Для этого от пользователя hadoop@${jn} выполним команды:

```
wget https://archive.apache.org/dist/hive/hive-4.0.0-alpha-2/apache-hive-4.0.0-alpha-2-bin.tar.gz
tar -xzvf apache-hive-4.0.0-alpha-2-bin.tar.gz
```

Переключимся по поддиректорию и скачаем драйвер hive:

```
cd apache-hive-4.0.0-alpha-2-bin/lib
wget https://jdbc.postgresql.org/download/postgresql-42.7.4.jar
```

Отредактируем конфиги. Создадим файл:

```
nano ../conf/hive-site.xml
```

Напишем содержимое:

```
<configuration>
	<property>
		<name>hive.server2.authentication</name>
		<value>NONE</value>
	</property>
	<property>
		<name>hive.metastore.warehouse.dir</name>
		<value>/user/hive/warehouse</value>
	</property>
	<property>
		<name>hive.server2.thrift.port</name>
		<value>5433</value>
		<description>TCP port number to listen on, default 10000</description>
	</property>
	<property>
		<name>javax.jdo.option.ConnectionURL</name>
		<value>jdbc:postgresql://${nn}:5432/metastore</value>
	</property>
	<property>
		<name>javax.jdo.option.ConnectionDriverName</name>
		<value>org.postgresql.Driver</value>
	</property>
	<property>
		<name>javax.jdo.option.ConnectionUserName</name>
		<value>hive</value>
	</property>
	<property>
		<name>javax.jdo.option.ConnectionPassword</name>
		<value>${hive-password}</value>
	</property>
</configuration>
```

Отредактируем файл, задающий переменные окружения:

```
nano ~/.profile
```

Добавим в конец строки:

```
export HIVE_HOME=/home/hadoop/apache-hive-4.0.0-alpha-2-bin
export HIVE_CONF_DIR=$HIVE_HOME/conf
export HIVE_AUX_JARS_PATH=$HIVE_HOME/lib/*
export PATH=$PATH:$HIVE_HOME/bin
```

Применим изменения:

```
source ~/.profile
```

Проверяем работу hive:

```
hive --version
```

Создадим директории (временную и для DWH, если такие не были созданы ранее) в hdfs:

```
hdfs dfs -mkdir /tmp
hdfs dfs -mkdir -p /user/hive/warehouse
```

Выдадим на них права:

```
hdfs dfs -chmod g+w /tmp
hdfs dfs -chmod g+w /user/hive/warehouse
```

Перейдём в директорию с hive и выполним инициализацию DWH:

```
cd ..
./bin/schematool -dbType postgres -initSchema
```

Запустим hive:

```
hive --hiveconf hive.server2.enable.doAs=false --hiveconf hive.security.authorization.enable=false --service hiveserver2 1>> /tmp/hs2.log 2>> /tmp/hs2.log &
```

Подключаемся:

```
beeline -u jdbc:hive2://${jn}:5433 -n scott -p tiger
```
