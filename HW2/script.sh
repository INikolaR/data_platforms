# params: path/to/hadoop ($1) jn-host-name ($2) nn-host-name ($3) dn-00-host-name ($4) dn-01-host-name ($5)

cat ./yarn-site.xml > $1/etc/hadoop/yarn-site.xml
cat ./mapred-site.xml > $1/etc/hadoop/mapred-site.xml
scp $1/etc/hadoop/yarn-site.xml $3:$1/etc/hadoop
scp $1/etc/hadoop/yarn-site.xml $4:$1/etc/hadoop
scp $1/etc/hadoop/yarn-site.xml $5:$1/etc/hadoop
scp $1/etc/hadoop/mapred-site.xml $3:$1/etc/hadoop
scp $1/etc/hadoop/mapred-site.xml $4:$1/etc/hadoop
scp $1/etc/hadoop/mapred-site.xml $5:$1/etc/hadoop