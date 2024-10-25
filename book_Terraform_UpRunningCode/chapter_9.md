pages 218-251

https://kodekloud.com/topic/playground-terraform-aws/

# Управление конфиденциальными данными

AWS Secret Manager

Используйте UI чтобы создать и сохранить секрет. Теперь вы сможете в своем коде Terraform использовать источник данных aws_secretsmanager_secret_version для чтения секрета db-creds:

data "aws_secretsmanager_secret_version" "creds" {
    secret_id = "db-creds"
}

Поскольку секрет хранится в формате JSON, для его анализа можно использовать функцию jsondecode и сохранить результат в локальной переменной db_creds:

locals {
    db_creds = jsondecode(
        data.aws_secretsmanager_secret_version.creds.secret_string
    )
}

А затем прочитать учетные данные для доступа к базе данных из db_creds и передать их в ресурс aws_db_instance:

resource "aws_db_instance" "example" {
    identifier_prefix = "terraform-up-and-running"
    engine = "mysql"
    allocated_storage = 10
    instance_class = "db.t2.micro"
    skip_final_snapshot = true
    db_name = var.db_name

    #Передача секретов в ресурс
    username = local.db_creds.username
    password = local.db_creds.password
}


# Резюме
1. Во-первых, вы можете не запоминать ничего из этой главы, кроме одного: не храните секреты в открытом виде.
2. Во-вторых, для передачи секретов провайдерам пользователи-люди могут использовать менеджеры личных секретов и создавать переменные окружения, а пользователи-компьютеры — использовать хранимые учетные данные, роли IAM или OIDC.
3. В-третьих, для передачи секретов ресурсам и источникам данных используйте переменные окружения, зашифрованные файлы или централизованные хранилища секретов.
4. И наконец, в-четвертых: запомните, что независимо от способа передачи секретов ресурсам и источникам данных Terraform будет выводить эти секреты в файлы состояния и файлы планов в открытом виде, поэтому всегда шифруйте эти файлы (при передаче и перед записью на диск) и строго контролируйте доступ к ним.