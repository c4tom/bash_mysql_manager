#!/bin/bash

# Array contendo os perfis/administrative roles
DB_PERFIS=("DBA"
    "MaintenanceAdmin"      # Direitos necessários para manter o servidor
    "ProcessAdmin"          # Direitos necessarios para monitorar, matar qualquer processos de usuários rodando no servidor
    "UserAdmin"             # Direitos para criar usuários e resetar senhas
    "SecurityAdmin"         # Direitos para gerenciar logins e conceder e revogar permissões de nível de servidor e banco de dados
    "MonitorAdmin"          # Permissões minimas para monitorar o servidor
    "DBManager"             # Concede direitos totais em todos os bancos de dados
    "DBDesigner"            # Direitos para criar e fazer engenharia reversa de qualquer esquema de banco de dados
    "ReplicationAdmin"      # Direitos necessários para configurar e gerenciar a replicação
    "BackupAdmin"           # Direitos mínimos necessários para fazer backup de qualquer banco de dados
    "Wordpress"             # Permissões minimas para uso do wordpress e wp-cli
    "CRUD"                  # Criar, Ler, Atualizar e Remover
)

# Associar os privilégios a cada perfil
DB_PERFIS_PRIVILEGIOS=(
    # Privilégios para o perfil "DBA"
    "ALL PRIVILEGES"
    # Privilégios para o perfil "MaintenanceAdmin"
    "EVENT, RELOAD, SHOW DATABASES, SHUTDOWN, SUPER"
    # Privilégios para o perfil "ProcessAdmin"
    "RELOAD, SUPER"
    # Privilégios para o perfil "UserAdmin"
    "CREATE USER, RELOAD"
    # Privilégios para o perfil "SecurityAdmin"
    "ALTER, CREATE, DROP, INDEX, SELECT, INSERT, UPDATE, DELETE"
    # Privilégios para o perfil "MonitorAdmin"
    "PROCESS"
    # Privilégios para o perfil "DBManager"
    "ALTER, ALTER ROUTINE, CREATE, CREATE ROUTINE, CREATE TEMPORARY TABLE, CREATE VIEW, DELETE, DROP, EVENT, GRANT OPTION, INDEX, INSERT, LOCK TABLES, SELECT, SHOW DATABASES, SHOW VIEW, TRIGGER, UPDATE"
    # Privilégios para o perfil "DBDesigner"
    "ALTER, ALTER ROUTINE, CREATE, CREATE ROUTINE, CREATE VIEW, INDEX, SHOW DATABASES, SHOW VIEW, TRIGGER"
    # Privilégios para o perfil "ReplicationAdmin"
    "REPLICATION CLIENT, REPLICATION SLAVE, SUPER"
    # Privilégios para o perfil "BackupAdmin"
    "EVENT, LOCK TABLES, SELECT, SHOW DATABASES"
    # Privilégios para o perfil "Wordpress"
    "SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, INDEX, DROP, FILE, SHOW VIEW, RELOAD, LOCK TABLES"
    # Privilégios para o perfil "CRUD"
    "SELECT, INSERT, UPDATE, DELETE"
)
# Loop para percorrer os perfis e privilégios correspondentes
for ((i=0; i<${#DB_PERFIS[@]}; i++))
do
    # Acessando o perfil atual através do índice "i" no array "perfis"
    PERFIL="${DB_PERFIS[i]}"
    
    # Acessando os privilégios correspondentes ao perfil atual através do índice "i" no array "privilegios"
    PRIVILEGIO="${DB_PERFIS_PRIVILEGIOS[i]}"
    
    # Imprimindo o perfil e seus privilégios
    echo "Perfil: $PERFIL"
    echo "Privilégios: $PRIVILEGIO"
done
