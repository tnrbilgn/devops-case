Kurulum İçin Aşağıdaki Adımlar sırası ile takip edilmelidir.

1-) Kademeli Kurulum

### Terraform ile GCP üzerinde kurulum
'''
   ~/devops-case/scripts/setup dizini içerisindeki install-with-terraform.sh scripti çalıştırılır.

   ./devops-case/scripts/setup/install-with-terraform.sh

   Bu script GCP üzerinde gerekli makinayı ve firewall kurallarını ayaklandıracak git repomuz makinaya kopyalanacak ve ardından makinamıza projemizde kullanmamız gereken uygulamaları ve kind clusterları yükleyecektir.

   Makinalara erişim için verilen pub/priv key kullanılabilir veya main.tf dosyası içerisinde hardcodding olarak verilen ssh key alanı değiştirilebilir.

'''
### Jenkins Kontrolü ve Arayüz Kurulumu
Terraform kurulumu sonrası makinaya ssh atılarak aşağıdaki komut ile Jenkins'in durumu kontrol edilir ve terraform'un sonunda verdiği VM external ip ile Jenkins arayüzüne erişim sağlanabilir.
'''
	sudo systemctl status jenkins.service
'''
Yukarıdaki kontrol sonrası jenkinse ait initialpassword görülecektir görülmemesi durumunda makinaya bağlanılarak aşağıdaki komut ile şifre edinilebilir.
'''
	sudo cat /var/lib/jenkins/secrets/initialAdminPassword

Şuanki URL : http://34.60.127.206:8080/
Şuanki Kullanıcı Adı : admin
Şifre : f8fb88023e8c4084a7eca730fb665acb
'''
Ve Jenkins kurulumları yapılır.

# HELM CHART ILE POSTGRESQL VE REDIS KURULUMU
'''
	~/devops-case/scripts/setup dizini içerisindeki helm-k8s.sh scripti çalıştırılır. Bu script Postgres ve Redis kurulumlarını tamamlayacaktır.
'''

### Jenkins Pipeline Çalıştırma
'''
	
	docker build -t flask-app:latest .
	kind load docker-image flask-app:latest --name devops-cluster

	sudo kubectl apply -f flask-app.yaml

# TEST SCRIPTLERI
GCP üzerindeki LoadBalancer kademesinde sorunlar yaşandığı için kurulumlarımı local olarak sağladım. Aşağıdaki scriptler vasıtası ile VM üzerindeki pod/servislerde gerekli kontroller sağlanacaktır.

##REDIS
'''
Vm üzerinden test için;

	~/devops-case/scripts/redis/redis-ping.sh
	
SSH vasıtası ile localinizden test için;

	~/devops-case/scripts/redis/redis-ping-ssh.sh
'''

##POSTGRES

Postgres üzerinde veri işlemek ve cache tutmak için basit bir yapı oluşturuldu bu sebeple gerekli tabloyu ve oluşturduğumuz kullanıcıya yetkileri vermek için aşağıdaki scriptler kullanılmalı, aynı zamanda bu scriptler pod'daki psql'in testinide sağlayacaktır.

'''
VM üzerinden test ve create için;

	~/devops-case/scripts/postgres/psql-create-table.sh
	
SSH vasıtası ile localinizden test ve create için;

	~/devops-case/scripts/postgres/psql-create-table-ssh.sh
'''

## FLASK

İstenilen işlemlerin kontrolü için API üzerinden input alan bir flask projesi yazıldı aşağıdaki script ile Postgres & Redis'in healthcheck'i veya Postgres'e input girilebilir.
'''

	~/devops-case/scripts/flask/flask-app-check-and-put.sh
'''
