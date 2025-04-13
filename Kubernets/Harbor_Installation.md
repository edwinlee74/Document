# Harbor 安裝
Harbor以Docker來部署, 只要你的Linux有支援Docker即可。

## Harware需求

|Resource|Minimum|Recommended|
|--------|-------|-----------|
|CPU     |2 CPU  |4 CPU      |
|Mem     |4 GB   |8 GB       |
|Disk    |40 GB  |160 GB     |

## Software需求

|Software      |Version                       |
|--------------|------------------------------|
|Docker Engine |Version 20.10.10-ce+ or higher|
|Docker Compose|docker-compose (v1.18.0+) or docker compose v2 (docker-compose-plugin)|
|OpenSSL       |Latest is preferred           |

## Network Port

|Port|Protocol|Description|
|----|--------|-----------|
|443 |HTTPS   |Harbor portal and core API accept HTTPS requests on this port. You can change this port in the configuration file.|
|4443|HTTPS   |Connections to the Docker Content Trust service for Harbor. You can change this port in the configuration file.|
|80  |HTTP    |Harbor portal and core API accept HTTP requests on this port. You can change this port in the configuration file.|

## 安裝

*  直接至[github](https://github.com/goharbor/harbor/releases?page=1)下載所要的版本, 有分online或offline二種方式。
*  安裝harbor之前需先安裝好docker。
```shell
 /* 解壓縮檔案 */
 # tar -zxvf harbor-online-installer-v2.12.2.tgz 
 # cd harbor

 /* 複製harbor.yml.tmpl */
 # cp harbor.yml.tmpl harbor.yml

 /* 編輯harbor.yml 
    hostname： 用以存取admin UI和registry service，IP 或 FQDN.
    certificate: 憑證位置。
    private_key: 私鑰位置。           
*/

 hostname: 192.168.20.12
 certificate: /data/cert/edwin.io.crt
 private_key: /data/cert/edwin.io.key 
 harbor_admin_password: Harbor12345     # 預設admin密碼
 password: root123           # 預設DB密碼   

/* 建立/data/cert目錄 */
# mkdir -p /data/cert

/* 建立CA憑證 */

1. CA certificate private key.
# openssl genrsa -out ca.key 4096

2. Generate the CA certificate.
# openssl req -x509 -new -nodes -sha512 -days 3650  -subj "/C=TW/ST=Kaohsiung/L=Kaohsiung/O=Gundam/OU=Personal/CN=Harbor Root CA"  -key ca.key  -out ca.crt

/* 產生server憑證 */
1. Generate a private key.
# openssl genrsa -out edwin.io.key 4096

2. Generate a certificate signing request (CSR).
# openssl req -sha512 -new -subj "/C=TW/ST=Kaohsiunt/L=Kaohsiung/O=Neweb/OU=Personal/CN=edwin.io" -key edwin.io.key -out edwin.io.csr

3. Generate an x509 v3 extension file.
# cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=yourdomain.com
DNS.2=yourdomain
DNS.3=hostname
EOF

4. Use the v3.ext file to generate a certificate for your Harbor host.
# openssl x509 -req -sha512 -days 3650 -extfile v3.ext -CA ca.crt -CAkey ca.key -CAcreateserial -in edwin.io.csr -out edwin.io.crt

/* 將上面產生的憑證提供給harbor及docker */

1. 複製到harbor主機上的/data/cert目錄
# cp edwin.io.crt /data/cert/
# cp edwin.io.key /data/cert/

2. 將edwin.io.crt轉換成edwin.io.cert給docker使用
# openssl x509 -inform PEM -in edwin.io.crt -out edwin.io.cert

3. 將server certificate, key and CA files複製到docker目錄
# cp edwin.io.cert /etc/docker/certs.d/edwin.io/
# cp edwin.io.key  /etc/docker/certs.d/edwin.io/
# cp ca.crt /etc/docker/certs.d/edwin.io/

4. Restart Docker Engine.
# systemctl restart docker

/* 設定harbor*/
1. Run the prepare script to enable HTTPS.
# ./prepare
# ./install.sh (如果尚未安裝)

2. If Harbor is running, stop and remove the existing instance.
# docker compose down -v

3. Restart Harbor:
# docker compose up -d

至此, 應該可以打開browser看到harbor介面了。
```

## 關機
```shell
 /* 在harbor目錄中下此指令 */

# docker compose stop
Stopping nginx              ... done
Stopping harbor-portal      ... done
Stopping harbor-jobservice  ... done
Stopping harbor-core        ... done
Stopping registry           ... done
Stopping redis              ... done
Stopping registryctl        ... done
Stopping harbor-db          ... done
Stopping harbor-log         ... done
```

## 開機
```shell
 /* 在harbor目錄中下此指令 */

# docker compose start
Starting log         ... done
Starting registry    ... done
Starting registryctl ... done
Starting postgresql  ... done
Starting core        ... done
Starting portal      ... done
Starting redis       ... done
Starting jobservice  ... done
Starting proxy       ... done
```

## 重新設定
```shell
1. Stop Harbor.
# docker compose down -v

2. Update harbor.yml
# vim harbor.yml

3. Run the prepare script to populate the configuration.
# ./prepare
  或是需要安裝Trivy,
# ./prepare --with-trivy

4. Re-create and start the Harbor instance.
# docker compose up -d

```

# 測試image上傳
```shell
/* loging 到 harbor */
# docker login https://harbor.myad.lab:5000

/* 將本地image 先做tag */
# docker tag hello-world:latest harbor.myad.lab:5000/library/myapp:v1.0

/* 推送imgage到harbor */
# docker push harbor.myad.lab:5000/library/myapp:v1.0




