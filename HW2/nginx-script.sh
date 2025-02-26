# namenode-host-name ($1) hadoop-port ($2) yarn-port ($3) dh-port ($4)

cp ./tmpl.conf /etc/nginx/sites-available/nn
cp ./tmpl.conf /etc/nginx/sites-available/ya
cp ./tmpl.conf /etc/nginx/sites-available/dh

sed -i "s/port_to_insert/$2/g" /etc/nginx/sites-available/nn
sed -i "s/host_to_insert/$1/g" /etc/nginx/sites-available/nn

sed -i "s/port_to_insert/$3/g" /etc/nginx/sites-available/ya
sed -i "s/host_to_insert/$1/g" /etc/nginx/sites-available/ya

sed -i "s/port_to_insert/$2/g" /etc/nginx/sites-available/dh
sed -i "s/host_to_insert/$1/g" /etc/nginx/sites-available/dh

ln -s /etc/nginx/sites-available/nn /etc/nginx/sites-enabled/nn
ln -s /etc/nginx/sites-available/ya /etc/nginx/sites-enabled/ya
ln -s /etc/nginx/sites-available/dh /etc/nginx/sites-enabled/dh
systemctl reload nginx
