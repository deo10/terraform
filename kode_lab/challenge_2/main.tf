#Create a terraform resource named php-httpd-image for building docker image with following specifications:
#Image name: php-httpd:challenge
#Build context: lamp_stack/php_httpd
#Labels: challenge: second

resource "docker_image" "php-httpd-image" {
  name = "php-httpd:challenge"
  build {
    path = "./lamp_stack/php_httpd"
    label = {
      challenge = "second"
    }
  }
}


#Create a terraform resource named mariadb-image for building docker image with following specifications:
#Image name: mariadb:challenge
#Build context: lamp_stack/custom_db
#Labels: challenge: second

resource "docker_image" "mariadb-image" {
  name = "mariadb:challenge"
  build {
    path = "lamp_stack/custom_db"
    label = {
      challenge = "second"
    }
  }
}

#Create a terraform resource named private_network and configure the following:
#Create a Docker network with name=my_network
#Enable manual container attachment to the network.
#User-defined key/value metadata: challenge: second

resource "docker_network" "private_network" {
  name       = "my_network"
  attachable = true
  labels {
    label = "challenge"
    value = "second"
  }
}


#Define a terraform resource php-httpd for creating docker container with following specification:
#Container Name: webserver
#Hostname: php-httpd
#Image used: php-httpd:challenge
#Attach the container to network my_network
#Publish a container's port(s) to the host:
#Hostport: 0.0.0.0:80
#containerPort: 80
#Labels: challenge: second
#Create a volume with host_path /root/code/terraform-challenges/challenge2/lamp_stack/website_content/ and container_path /var/www/html within webserver container.


resource "docker_container" "php-httpd" {
  name     = "webserver"
  image    = docker_image.php-httpd-image.name
  hostname = "php-httpd"
  networks_advanced {
    name = docker_network.private_network.id
  }
  ports {
    internal = 80
    external = 80
    ip       = "0.0.0.0"
  }
  labels {
    label = "challenge"
    value = "second"
  }
  volumes {
    container_path = "/var/www/html"
    host_path      = "/root/code/terraform-challenges/challenge2/lamp_stack/website_content/"
  }
}


#Define a terraform resource phpmyadmin for docker container with following configurations:
#Container Name: db_dashboard
#Image Used: phpmyadmin/phpmyadmin
#Hostname: phpmyadmin
#Attach the container to network my_network
#Publish a container's port(s) to the host:
#Hostport: 0.0.0.0:8081
#containerPort: 80
#Labels: challenge: second
#Establish link based connectivity between db and db_dashboard containers (Deprecated)
#Explicitly specify a dependency on mariadb terraform resource

resource "docker_container" "phpmyadmin" {
  name     = "db_dashboard"
  image    = "phpmyadmin/phpmyadmin"
  hostname = "phpmyadmin"
  networks_advanced {
    name = docker_network.private_network.id
  }
  ports {
    internal = 80
    external = 8081
    ip       = "0.0.0.0"
  }
  labels {
    label = "challenge"
    value = "second"
  }
  depends_on = [docker_container.mariadb]
}

#Create a terraform resource named mariadb_volume creating a docker volume with name=mariadb-volume

resource "docker_volume" "mariadb_volume" {
  name = "mariadb-volume"
}


#Define a terraform resource mariadb for creating docker container with following specification:
#Container Name: db
#Image Used: mariadb:challenge
#Hostname: db
#Attach the container to network my_network
#Publish a container's port(s) to the host:
#Hostport: 0.0.0.0:3306
#containerPort: 3306
#Labels: challenge: second
#Define environment variables inside mariadb resource:
#MYSQL_ROOT_PASSWORD=1234
#MYSQL_DATABASE=simple-website
#Attach volume mariadb-volume to /var/lib/mysql directory within db container.


resource "docker_container" "mariadb" {
  name     = "db"
  image    = docker_image.mariadb-image.name
  hostname = "db"
  networks_advanced {
    name = docker_network.private_network.id
  }
  ports {
    internal = 3306
    external = 3306
    ip       = "0.0.0.0"
  }
  labels {
    label = "challenge"
    value = "second"
  }
  env = [
    "MYSQL_ROOT_PASSWORD=1234",
    "MYSQL_DATABASE=simple-website"
  ]
  volumes {
    container_path = "/var/lib/mysql"
    volume_name    = docker_volume.mariadb_volume.name
  }
}