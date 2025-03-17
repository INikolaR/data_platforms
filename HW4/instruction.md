# Входные данные

```
${team} - пользователь с правами sudoers
${team-password} - пароль пользователя ${team}
${hadoop-password} - пароль пользователя hadoop
${jn} - имя хоста джамп ноды
${nn} - имя хоста нейм ноды
${dn-00} и ${dn-01} - имена хостов 0 и 1 датанод соответственно
${jn-ip}, ${nn-ip}, ${dn-00-ip} и ${dn-01-ip} - ip-адреса всех этих хостов в локальной сети соответственно
```

# Настройка

На \${team}@\${jn} выполним (введя пароль ${team-password} для sudo):

```
sudo apt install python3-venv
sudo apt install python3-pip
```

Это поможет установить необходимые библиотеки.

Переключимся на пользователя hadoop:

```
sudo -i -u hadoop
```

Скачаем spark:

```
wget https://archive.apache.org/dist/spark/spark-3.5.3/spark-3.5.3-bin-hadoop3.tgz
tar -xzvf spark-3.5.3-bin-hadoop3.tgz
```

Настроим переменные окружения. Добавим в .profile строки:

```
export HADOOP_CONF_DIR="/home/hadoop/hadoop-3.4.0/etc/hadoop"
export SPARK_LOCAL_IP=${jn-ip}
export SPARK_DIST_CLASSPATH="/home/hadoop/spark-3.5.3-bin-hadoop3/jars/*:/home/hadoop/hadoop-3.4.0/etc/hadoop:/home/hadoop/hadoop-3.4.0/share/hadoop/common/lib/*:/home/hadoop/hadoop-3.4.0/share/hadoop/common/*:/home/hadoop/hadoop-3.4.0/share/hadoop/hdfs:/home/hadoop/hadoop-3.4.0/share/hadoop/hdfs/lib/*:/home/hadoop/hadoop-3.4.0/share/hadoop/hdfs/*:/home/hadoop/hadoop-3.4.0/share/hadoop/mapreduce/*:/home/hadoop/hadoop-3.4.0/share/hadoop/yarn:/home/hadoop/hadoop-3.4.0/share/hadoop/yarn/lib/*:/home/hadoop/hadoop-3.4.0/share/hadoop/yarn/*:/home/hadoop/apache-hive-4.0.0-alpha-2-bin/*:/home/hadoop/apache-hive-4.0.0-alpha-2-bin/lib/*"
export SPARK_HOME="/home/hadoop/spark-3.5.3-bin-hadoop3"
export PYTHONPATH=$(ZIPS=("$SPARK_HOME"/python/lib/*.zip); IFS=:; echo "${ZIPS[*]}"):$PYTHONPATH
export PATH=$SPARK_HOME/bin:$PATH
```

важно: ${jn-ip} заменить на значение. Такие переменные, как SPARK_HOME, здесь не устанавливаются, так как они были установлены в предыдущем семинаре.

Вернёмся в ~:

```
cd ~
```

Запустим сервис metastore:

```
hive --service metastore &
```

Создадим и активируем среду:

```
python3 -m venv venv
source venv/bin/activate
```

Обновим pip и установим ipython:

```
pip install -U pip
pip install ipython
pip install onetl[files]
```

Все пакеты установлены.

# Помещение файла в hdfs

Будем считать, что всё из предыдущих ДЗ было корректно развёрнуто. Проверим наличие директории /input и hdfs:

```
hdfs dfs -ls /
```

Если нет - создаём:

```
hdfs dfs -mkdir /input
hdfs dfs -chmod g+w /input
```

Пусть мы хотим с помощью spark обработать файл titanic.csv, который лежит в директории ~.

```
wget https://github.com/INikolaR/data_platforms/raw/master/titanic.csv
```

Положим этот файл в hdfs

```
hdfs dfs -put titanic.csv /input
```

Проверим, что файл появился:

```
hdfs dfs -ls /input
```

Также проверим, что база данных создана:

```
hdfs dfs -ls /user/hive/warehouse
```

Если директория пуста - создаём базу. Подключаемся к hive:

```
beeline -u jdbc:hive2://${jn}:5433 -n scott -p tiger
```

Создадим базу:

```
CREATE DATABASE test;
```

Закроем соединение:

```
ctrl+c
```

# Обработка с помощью ipython

Для обработки запустим ipython:

```
ipython
```

Напишем немного кода:

```
from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from onetl.connection import SparkHDFS
from onetl.connection import Hive
from onetl.file import FileDFReader
from onetl.file.format import CSV
from onetl.db import DBWriter
spark = SparkSession.builder.master("yarn").appName("spark-with-yarn").config("spark.sql.warehouse.dir", "/user/hive/warehouse").config("spark.hive.metastore.uris", "thrift://jn:9083").enableHiveSupport().getOrCreate()
```

важно: вместо ${jn} нужно вставить его знчение.

```
hdfs = SparkHDFS(host="nn", port=9000, spark=spark, cluster="test")
hdfs.check()
```

Ожидаем вывод в духе:

```
SparkHDFS(cluster='test', host='nn', ipc_port=9000)
```

Выполняем чтение и применяем 2 трансформации: фильтрация по возрасту и конвертирование возраста в double

```
reader = FileDFReader(connection=hdfs, format=CSV(delimiter=",", header=True), source_path="/input")
raw_df = reader.run(["titanic.csv"])
transformed_df = raw_df \
    .filter(raw_df["Age"] > 10) \
    .withColumn("Age_double", F.col("Age").cast("double"))

```

Сохраняем с партицированием:

```
hive = Hive(spark=spark, cluster="test")
writer = DBWriter(
    connection=hive,
    table="test.spark_partitions",
    options={
        "if_exists": "replace_entire_table",
        "partition_by": ["Sex"]
    }
)
writer.run(transformed_df)
```

Выходим из ipython:

```
exit
```

Проверяем:

```
beeline -u jdbc:hive2://${jn}:5433 -n scott -p tiger
DESCRIBE FORMATTED test.spark_partitions;
SELECT * FROM spark_partitions LIMIT 10;
```
