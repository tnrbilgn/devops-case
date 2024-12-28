Kurulum İçin Aşağıdaki Adımlar sırası ile takip edilmelidir.

'''
ssh-keygen -t rsa -b 4096 -C "tanerbilgin94" -f ~/.ssh/devops-test
'''

Yukarıdaki komut ile scriptlerimizde ve terraformumuzda kullanılmak üzere ssh key çifti üretilecektir ve terraform-full klasörü içine bir kopyası taşınmalıdır.

### Terraform ile GCP üzerinde kurulum

~/devops-case/scripts/setup dizini içerisindeki terraform-install scripti çalıştırılır.

'''
   ./devops-case/scripts/setup/terraform-install

   Bu script GCP üzerinde gerekli makinayı ve firewall kurallarını ayaklandıracak scriptleri makinaya kopyalanacak ve ardından makinamıza projemizde kullanmamız gereken uygulamaları ve kind clusterları yükleyecektir.

   Makinalara erişim için verilen pub/priv key kullanılabilir veya main.tf dosyası içerisinde hardcodding olarak verilen ssh key alanı değiştirilebilir.

'''
### Jenkins Kontrolü ve Arayüz Kurulumu
Terraform kurulumu sonrası makinaya ssh atılarak aşağıdaki komut ile Jenkins'in durumu kontrol edilir ve terraform'un sonunda verdiği VM external ip ile Jenkins arayüzüne erişim sağlanabilir.
'''
	http://<<VM_EXTERNAL_IP>>:8080
'''
'''
	./devops-case/scripts/setup/jenkins-pw
'''
Yukarıdaki script ile jenkinse ait initialpassword görülenebilir ve arayüzden giriş yapıldığında kullanılabilir.

Alternatif olarak VM içerisinde aşağıdaki dizinde'de bulabilirsiniz.
'''
	sudo cat /var/lib/jenkins/secrets/initialAdminPassword

'''
#Postgres Tablo Oluşturma
Farklı bir yöntem olması açısıyla VM üzerindeki podumuza bağlanarak PSQL ile gerekli inputlar için tablo oluşturulur ve kullancımıza yetkiler verilir.

'''

	./devops-case/sripts/postgres/psql-create-table-ssh

'''
### Jenkins Pipeline Çalıştırma
'''
	./devops-cluster/jenkins/jenkins-pipeline
'''
Scriptimiz jenkins içerisine manuel verilerek test için oluşturulmuş flask uygulamamızın kind clusterimize deployunu yapar.

# TEST SCRIPTLERI

##REDIS
'''

	~/devops-case/scripts/redis/redis-ping
	
'''

##POSTGRES

'''
	~/devops-case/scripts/postgres/psql-create-table.sh
	
'''

## FLASK

İstenilen işlemlerin kontrolü için API üzerinden input alan bir flask projesi yazıldı aşağıdaki script ile Postgres & Redis'in healthcheck'i veya Postgres'e input girilebilir.
'''

	~/devops-case/scripts/flask/flask-app-check-and-put
'''
