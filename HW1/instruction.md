# Инструкция

0. Конфигурация:
   Обозначим данные нам локальные адреса:

   ```
   ${jn-ip} - ip-адрес jump node
   ${nn-ip} - ip-адрес name node
   ${dn-00-ip} - ip-адрес data node 1
   ${dn-01-ip} - ip-адрес data node 2
   ${ex-ip} - внешний адрес подключения jump node
   ${ssk-key-jn} - ключ подключения к jn извне
   ${user} - имя пользователя (у нас у всех, вроде как, team)
   ${password} - пароль от пользователя ${user} всех нод
   ```

В условии указано, что артефакты предполагают развёртывание в аналогичной, но не идентичной среде. Все данные выше в общем случае могут отличаться от тех, что нам выдали. По факту эти данные являются входными данными алгоритма настройки системы. Поэтому эти обозначения введены для удобства и используются только в рамках инструкции для обеспечения корректности алгоритма для других аналогичных систем.

## Подключение и настройка доступа

Подключимся к системе командой:

```
ssh ${user}@${ex-ip}
```

Вводим пароль:

```
${ssh-key-jn}
```

Мы вошли на джамп-ноду. Нужно сгенерировать ssh-ключ для быстрого переключения между нодами:

```
ssh-keygen
```

Появились файлы .ssh/id_ed25519 и .ssh/id_ed25519.pub. Добавим ключ в авторизованные:

```
cat .ssh/id_ed15519.pub >> .ssh/authorized_keys
```

Скопируем список авторизованных ключей на все ноды:

```
scp .ssh/authorized_keys ${nn-ip}:/home/${user}/.ssh/
scp .ssh/authorized_keys ${dn-00-ip}:/home/${user}/.ssh/
scp .ssh/authorized_keys ${dn-01-ip}:/home/${user}/.ssh/
```

После каждой введённой команды необходимо ввести пароль ${password}.

Для краткости далее при запуске любой команды, требующей ввода пароля пользователя \${user}, по умолчанию будем подразумевать ввод пароля \${password}. Аналогично с созданным ниже пользователем hadoop.

Теперь нам нужно настроить имена хостов и создать пользователя hadoop на каждой ноде. Для этого пропишем

```
sudo nano /etc/hosts
```

По умолчанию подразумевается, что пользователь инструкции умеет редактировать файлы с помощью nano. В противном случае можно ознакомиться с документацией по ссылке: https://www.nano-editor.org/dist/latest/nano.pdf

Добавим в начало файла следующие строки:

```
${jn-ip} jn
${nn-ip} nn
${dn-00-ip} dn-00
${dn-01-ip} dn-01
```

Создадим пользователя hadoop:

```
sudo adduser hadoop
```

Установим ему пароль ${hpassword} (необходимо придумать любой надёжный), остальные поля оставим пустыми.

Переключимся на нейм-ноду:

```
ssh nn
```

Отредактируем /etc/hosts:

```
sudo nano /etc/hosts
```

Добавим в начало файла следующие строки:

```
${jn-ip} jn
${nn-ip} nn
${dn-00-ip} dn-00
${dn-01-ip} dn-01
```

Создадим пользователя hadoop:

```
sudo adduser hadoop
```

Установим ему пароль ${hpassword}, остальные поля оставим пустыми.

Вернёмся на джамп-ноду:

```
exit
```

Переключимся на дата-ноду-1:

```
ssh dn-00
```

Отредактируем /etc/hosts:

```
sudo nano /etc/hosts
```

Добавим в начало файла следующие строки:

```
${jn-ip} jn
${nn-ip} nn
${dn-00-ip} dn-00
${dn-01-ip} dn-01
```

Создадим пользователя hadoop:

```
sudo adduser hadoop
```

Установим ему пароль ${hpassword}, остальные поля оставим пустыми.

Вернёмся на джамп-ноду:

```
exit
```

Переключимся на дата-ноду-2:

```
ssh dn-01
```

Отредактируем /etc/hosts:

```
sudo nano /etc/hosts
```

Добавим в начало файла следующие строки:

```
${jn-ip} jn
${nn-ip} nn
${dn-00-ip} dn-00
${dn-01-ip} dn-01
```

Создадим пользователя hadoop:

```
sudo adduser hadoop
```

Установим ему пароль ${hpassword}, остальные поля оставим пустыми.

Вернёмся на джамп-ноду:

```
exit
```

Перейдём в пользователя hadoop:

```
sudo -i -u hadoop
```

Сгенерируем ssh-ключ и разложим его по остальным хостам:

```
ssh-keygen
cat .ssh/id_ed25519.pub > .ssh/authorized_keys
scp -r .ssh/ nn:/home/hadoop
scp -r .ssh/ dn-00:/home/hadoop
scp -r .ssh/ dn-01:/home/hadoop
```

## Скачивание hadoop

В данный момент мы находимся в директории ~ пользователя hadoop на джамп-ноде. Скачаем архив с hadoop:

```
wget https://dlcdn.apache.org/hadoop/common/hadoop-3.4.0/hadoop-3.4.0.tar.gz
```

Распространим архив по всем машинам:

```
scp hadoop-3.4.0.tar.gz nn:/home/hadoop
scp hadoop-3.4.0.tar.gz dn-00:/home/hadoop
scp hadoop-3.4.0.tar.gz dn-01:/home/hadoop
```

Распакуем архив на каждой ноде:

```
tar -xzvf hadoop-3.4.0.tar.gz
ssh nn
tar -xzvf hadoop-3.4.0.tar.gz
exit
ssh dn-00
tar -xzvf hadoop-3.4.0.tar.gz
exit
ssh dn-01
tar -xzvf hadoop-3.4.0.tar.gz
exit
```

## Настройка окружения

Убедимся, что версия java подходит нам:

```
java --version
```

Найдём где расположен файл:

```
which java | xargs readlink -f
```

Получаем примерно следующий вывод:

```
${path-to-java}/bin/java
```

где ${path-to-java} - какой-то путь, конкретный путь зависит от версии, просто запомним его.

Отредактируем файл .profile:

```
nano .profile
```

Добавим в конец следующие строки:

```
export HADOOP_HOME=/home/hadoop/hadoop-3.4.0
export JAVA_HOME=${path-to-java}
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
```

где ${path-to-java} - путь, найденный предыдущей командой.

Активируем изменения:

```
source .profile
```

Можем убедиться, что hadoop работает:

```
hadoop version
```

Раскидаем файл на все машины:

```
scp .profile nn:/home/hadoop
scp .profile dn-00:/home/hadoop
scp .profile dn-01:/home/hadoop
```

Перейдём в директорию с конфигами:

```
cd hadoop-3.4.0/etc/hadoop/
```

Отредактируем файл hadoop-env.sh:

```
nano hadoop-env.sh
```

Добавим в конец строку:

```
JAVA_HOME=${path-to-java}
```

где ${path-to-java} - ранее найденный путь.

Отредактируем файл core-site.xml:

```
nano core-site.xml
```

Строки

```
<configuration>
</configuration>
```

заменим на

```
<configuration>
<property>
        <name>fs.defaultFS</name>
        <value>hdfs://nn:9000</value>
</property>
</configuration>
```

Отредактируем файл hdfs-core.xml:

```
nano hdfs-core.xml
```

Строки

```
<configuration>
</configuration>
```

заменим на

```
<configuration>
<property>
	<name>dfs.replication</name>
	<value>3</value>
</property>
</configuration>
```

Отредактируем файл workers:

```
nano workers
```

Заменим строку

```
localhost
```

на

```
nn
dn-00
dn-01
```

Распространим изменения по всем машинам:

```
scp hadoop-env.sh nn:/home/hadoop/hadoop-3.4.0/etc/hadoop
scp hadoop-env.sh dn-00:/home/hadoop/hadoop-3.4.0/etc/hadoop
scp hadoop-env.sh dn-01:/home/hadoop/hadoop-3.4.0/etc/hadoop

scp core-site.xml nn:/home/hadoop/hadoop-3.4.0/etc/hadoop
scp core-site.xml dn-00:/home/hadoop/hadoop-3.4.0/etc/hadoop
scp core-site.xml dn-01:/home/hadoop/hadoop-3.4.0/etc/hadoop

scp hdfs-site.xml nn:/home/hadoop/hadoop-3.4.0/etc/hadoop
scp hdfs-site.xml dn-00:/home/hadoop/hadoop-3.4.0/etc/hadoop
scp hdfs-site.xml dn-01:/home/hadoop/hadoop-3.4.0/etc/hadoop

scp workers nn:/home/hadoop/hadoop-3.4.0/etc/hadoop
scp workers dn-00:/home/hadoop/hadoop-3.4.0/etc/hadoop
scp workers dn-01:/home/hadoop/hadoop-3.4.0/etc/hadoop
```

## Форматирование файловой системы

Переключимся на нэйм-ноду:

```
ssh nn
```

Отформатируем файловую систему:

```
hadoop-3.4.0/bin/hdfs namenode -format
```

Запустим кластер:

```
hadoop-3.4.0/sbin/start-dfs.sh
```

Удостоверимся, что в логах всё в порядке:

```
tail hadoop-3.4.0/logs/hadoop-hadoop-datanode-*-nn.log
```

```
tail hadoop-3.4.0/logs/hadoop-hadoop-namenode-*-nn.log
```

Проверим на дата-нодах:

```
ssh dn-00
tail hadoop-3.4.0/logs/hadoop-hadoop-datanode-*-dn-00.log
```

```
ssh dn-01
tail hadoop-3.4.0/logs/hadoop-hadoop-datanode-*-dn-01.log
```

Если нет ошибок (а их не должно быть) - кластер поднялся.
