#!/bin/bash

# Array para armazenar as regras e privilégios
declare -A roles_privileges

# Executar o comando no MariaDB
output=$(mysql -uroot -psenhasenha -e "SELECT DISTINCT r.`User`, r.`Host`, r.`Super_priv`, r.`Reload_priv`, r.`Shutdown_priv`, r.`Process_priv`, r.`File_priv`, r.`Grant_priv`, r.`References_priv`, r.`Index_priv`, r.`Alter_priv`, r.`Show_db_priv`, r.`Super_priv`, r.`Create_tmp_table_priv`, r.`Lock_tables_priv`, r.`Execute_priv`, r.`Create_routine_priv`, r.`Alter_routine_priv`, r.`Create_view_priv`, r.`Show_view_priv`, r.`Create_user_priv`, r.`Event_priv`, r.`Trigger_priv`, r.`Create_tablespace_priv`
FROM mysql.`user` r
WHERE r.`User` != 'root'")

# Analisar a saída para preencher o array
while IFS= read -r line; do
    role=$(echo "$line" | cut -d ' ' -f 1)
    privileges=$(echo "$line" | cut -d ' ' -f 2-)
    roles_privileges["$role"]="$privileges"
done <<< "$output"

# Exibir as regras e privilégios
for role in "${!roles_privileges[@]}"; do
    echo "Regra: $role"
    echo "Privilégios: ${roles_privileges[$role]}"
    echo
done
