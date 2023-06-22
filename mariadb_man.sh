#!/bin/bash

# Variáveis globais
ARQUIVO_INI=${1:-"/root/.myini"} # contém host, user, password

HOST_DEFAULT="%"

PERMISSOES_DEFAULT="SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES"

BACKUP_DIR="/dados/backup"

ECHO_CMD=false # se for true, todos os comandos serão impressos na tela e depois executados

DB_CHECK_ITEMS="FOR UPGRADE, QUICK, FAST, MEDIUM, EXTENDED, CHANGED"
DB_CHECK_SUM="QUICK, EXTENDED"
DB_REPAIR="QUICK, EXTENDED, USE_FRM"

DB_SELECTED="" # será usado para memorizar o banco de dados selecionado

ULTIMA_FUNCAO="" # Ultima funcao executada, para retorno do menu

# Array contendo todos os privilégios disponíveis
PRIVILEGIOS=(
    "ALL PRIVILEGES"               # Todos os privilégios possíveis
    "ALTER"                        # Permite alterar a estrutura de tabelas existentes
    "ALTER ROUTINE"                # Permite alterar rotinas existentes
    "CREATE"                       # Permite criar novos bancos de dados e tabelas
    "CREATE ROLE"                  # Permite criar novos papéis de usuário
    "CREATE ROUTINE"               # Permite criar rotinas (procedimentos armazenados e funções)
    "CREATE TABLESPACE"            # Permite criar tablespaces
    "CREATE TEMPORARY TABLES"      # Permite criar tabelas temporárias
    "CREATE USER"                  # Permite criar novos usuários
    "CREATE VIEW"                  # Permite criar novas views
    "DELETE"                       # Permite excluir registros de tabelas
    "DROP"                         # Permite excluir bancos de dados e tabelas
    "DROP ROLE"                    # Permite excluir papéis de usuário
    "EVENT"                        # Permite criar, alterar e excluir eventos
    "EXECUTE"                      # Permite executar procedimentos armazenados e funções
    "FILE"                         # Permite acessar arquivos no servidor
    "GRANT ANY ROLE"               # Permite conceder qualquer papel de usuário a outros usuários
    "GRANT OPTION"                 # Permite conceder privilégios a outros usuários
    "INDEX"                        # Permite criar índices em tabelas
    "INSERT"                       # Permite inserir novos registros em tabelas
    "LOCK TABLES"                  # Permite bloquear tabelas para uso exclusivo
    "PROCESS"                      # Permite visualizar e matar processos de outros usuários
    "REFERENCES"                   # Permite criar chaves estrangeiras em tabelas
    "RELOAD"                       # Permite recarregar configurações do servidor
    "REPLICATION CLIENT"           # Permite acessar informações sobre a replicação
    "REPLICATION SLAVE"            # Permite atuar como um slave em uma replicação de banco de dados
    "SELECT"                       # Permite realizar consultas (seleção) nos dados
    "SHOW DATABASES"               # Permite visualizar os bancos de dados disponíveis
    "SHOW VIEW"                    # Permite visualizar a definição de views
    "SUPER"                        # Permite executar comandos com privilégios de superusuário
    "SHUTDOWN"                     # Permite desligar o servidor do banco de dados
    "TRIGGER"                      # Permite criar, alterar e excluir gatilhos
    "UPDATE"                       # Permite atualizar registros existentes em tabelas
)


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

Color_Off='\033[0m'       # Text Reset
BYellow='\033[1;33m'      # Yellow
IPurple='\033[0;95m'      # Purple

echoColor() {
	echo -e "$Color_Off$1$Color_Off"
}
# Função para imprimir os comandos executados em modo debug
echo_and_run() {
    if [ "${ECHO_CMD}" = "true" ]; then
        echoColor "$BYellow""command>$IPurple $*" ; "$@" ; 
    else 
        "$@" ;
    fi
}

check_dependencias() {
    local missing_dependencies=()

    # Verifica se o comando 'mysql' está disponível
    if ! command -v mysql &> /dev/null; then
        missing_dependencies+=("mysql")
    fi

    # Verifica se o comando 'mysqldump' está disponível
    if ! command -v mysqldump &> /dev/null; then
        missing_dependencies+=("mysqldump")
    fi

    # Verifica se há dependências ausentes e exibe uma mensagem
    if [[ ${#missing_dependencies[@]} -gt 0 ]]; then
        echo "As seguintes dependências estão ausentes:"
        for dependency in "${missing_dependencies[@]}"; do
            echo " - $dependency"
        done
        exit 1
    fi
}


# Função para gerar uma senha aleatória
generate_password() {
    local length=${1:-15}
    local chars=${2:-"LUNS"}
    local password=""

    local lowercase='abcdefghijklmnopqrstuvwxyz'
    local uppercase='ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local numbers='0123456789'
    local special_chars='!@#$%^&*()_-+=<>?{}[];,.'

    local all_chars=''

    if [[ $chars == *"L"* ]]; then
        all_chars+=" $lowercase"
    fi

    if [[ $chars == *"U"* ]]; then
        all_chars+=" $uppercase"
    fi

    if [[ $chars == *"N"* ]]; then
        all_chars+=" $numbers"
    fi

    if [[ $chars == *"S"* ]]; then
        all_chars+=" $special_chars"
    fi

    all_chars=$(echo "$all_chars" | tr -d ' ')

    local num_chars=${#all_chars}

    for ((i=0; i<length; i++)); do
        local random_index=$((RANDOM % num_chars))
        password+=${all_chars:$random_index:1}
    done

    echo "$password"
}



# Função para ler um arquivo INI (seção>attributos)
#[client]
#host = localhost
#user = meu_usuario
#password = minha_senha
#port = 3306

read_ini_file() {
  local ini_file=$1
  local section=$2
  local key=$3
  local value=$(awk -F "=" -v section="$section" -v key="$key" '$1 == "[" section "]" { in_section = 1 } in_section == 1 && $1 == key { print $2; exit }' "$ini_file")
  echo "$value"
}

mysql_cmd() {
    MYSQL_CMD="mysql --defaults-file=$ARQUIVO_INI"
}

obter_db_lista_usuarios() {
    # Executa a consulta SQL para obter a lista de usuários
    local query="SELECT user FROM mysql.user WHERE USER NOT IN ('root')"

    # Executa o comando MySQL e retorna a lista de usuários
    $MYSQL_CMD -e "$query" -s -N
}


obter_db_lista_databases() {
    # Executa a consulta SQL para obter a lista de bancos de dados
    local query="SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME NOT IN ('information_schema')"

    # Executa o comando MySQL e retorna a lista de bancos de dados
    $MYSQL_CMD -e "$query" -s -N
}

obter_db_lista_privilegios_usuario() {
    local usuario
    obter_db_lista_usuarios # Chamada da função para obter a lista de usuários e apresentar como menu

    echo "Digite o número correspondente ao usuário: "
    read -r usuario

    # Verifica se o número do usuário é válido
    if [[ $usuario =~ ^[0-9]+$ && $usuario -ge 1 && $usuario -le "${#USUARIOS[@]}" ]]; then
        local nome_usuario="${USUARIOS[$usuario - 1]}"

        # Obter os privilégios do usuário no banco de dados
        local query="SELECT privilege_type FROM information_schema.user_privileges WHERE grantee = '${nome_usuario}'"
        local privilegios=$(echo_and_run mysql -N -e "$query")

        # Associar os privilégios obtidos com o array PRIVILEGIOS
        local privilegios_associados=()
        for priv in $privilegios; do
            for i in "${!PRIVILEGIOS[@]}"; do
                if [[ "${PRIVILEGIOS[$i]}" == "$priv" ]]; then
                    privilegios_associados+=("$priv")
                    break
                fi
            done
        done

        # Apresentar os privilégios associados ao usuário
        echo "Privilégios do usuário ${nome_usuario}:"
        for priv in "${privilegios_associados[@]}"; do
            echo "- $priv"
        done
    else
        echo "Número de usuário inválido."
    fi
}


show_database_menu() {
    local databases=$(obter_db_lista_databases)
    local db_count=0
    local selected_db=""

    echo "Selecione um banco de dados:"

    # Loop sobre a lista de bancos de dados e exibe o menu numerado
    while read -r db_name; do
        db_count=$((db_count + 1))
        echo "$db_count. $db_name"
    done <<< "$databases"

    # Solicita a entrada do usuário para selecionar um número
    read -p "Digite o número correspondente ao banco de dados desejado: " choice

    # Verifica se a escolha do usuário é um número válido
    if [[ $choice =~ ^[0-9]+$ ]] && ((choice >= 1)) && ((choice <= db_count)); then
        # Obtém o nome do banco de dados selecionado com base no número escolhido
        selected_db=$(echo "$databases" | sed -n "${choice}p")
        DB_SELECTED=$selected_db
    else
        echo "Escolha inválida. Por favor, tente novamente."
        show_database_menu
    fi

    echo "Banco de dados selecionado: $selected_db"
    $ULTIMA_FUNCAO
    return 0
}

show_database_properties() {
    local database="$1"

    # Executa a consulta SQL para obter as propriedades do banco de dados
    local query="SELECT DEFAULT_CHARACTER_SET_NAME AS DefaultCharset, DEFAULT_COLLATION_NAME AS DefaultCollation FROM information_schema.SCHEMATA WHERE SCHEMA_NAME = '$database';"

    # Executa o comando MySQL e exibe as propriedades do banco de dados
    $MYSQL_CMD -e "$query"
}


# Função para mostrar as propriedades do banco de dados
show_database_properties() {
  if [ -z "$DB_SELECTED" ]; then
    echo "Nenhum banco de dados selecionado."
    show_database_menu
  fi

  echo "=== Propriedades do Banco de Dados ==="
  echo "Nome: $DB_SELECTED"
  echo "Charset: utf8mb4"
  echo "Collate: utf8_unicode_ci"
}

# Função para exibir o menu de gerenciamento de tabelas
show_table_management_menu() {
  if [ -z "$DB_SELECTED" ]; then
    echo "Nenhum banco de dados selecionado."
    show_database_menu
  fi

  echo "=== Gerenciamento de Tabelas ==="
  echo "1 - Checar"
  echo "2 - Analisar"
  echo "3 - Checksum"
  echo "4 - Otimizar"
  echo "5 - Reparar"
  echo "0 - Voltar"

  read -p "Escolha uma opção: " option
  case $option in
    1)
      echo "Checando tabelas..."
      # Comando para checar tabelas
      ;;
    2)
      echo "Analisando tabelas..."
      # Comando para analisar tabelas
      ;;
    3)
      echo "Calculando checksum das tabelas..."
      # Comando para calcular checksum das tabelas
      ;;
    4)
      echo "Otimizando tabelas..."
      # Comando para otimizar tabelas
      ;;
    5)
      echo "Reparando tabelas..."
      # Comando para reparar tabelas
      ;;
    0)
      echo "Voltando..."
      ;;
    *)
      echo "Opção inválida"
      ;;
  esac
}

# Função para exibir o menu de backup/restauração
show_backup_restore_menu() {
  echo "=== Backup / Restauração ==="
  echo "1 - Backup físico"
  echo "2 - Backup lógico"
  echo "0 - Voltar"

  read -p "Escolha uma opção: " option
  case $option in
    1)
      echo "Realizando backup físico..."
      # Comando para fazer backup físico
      ;;
    2)
      echo "Realizando backup lógico..."
      # Comando para fazer backup lógico
      ;;
    0)
      echo "Voltando..."
      ;;
    *)
      echo "Opção inválida"
      ;;
  esac
}


show_process_list() {
    while true; do
        clear
        echo "=== Lista de Processos ==="
        $MYSQL_CMD -e "SHOW FULL PROCESSLIST;"

       echo "Pressione qualquer tecla para sair..."

        read -t 1 -n 1
        if [ $? = 0 ]; then
            break
        fi

    done
}

show_query_list() {
    while true; do
        clear
        echo "=== Lista de Queries ==="
        $MYSQL_CMD -e "SHOW FULL PROCESSLIST\G"

       echo "Pressione qualquer tecla para sair..."

        read -t 1 -n 1
        if [ $? = 0 ]; then
            break
        fi
    done
}

# Função para exibir o menu de status e monitoramento
show_status_monitoring_menu() {
    local choice

    while true; do
        clear
        echo "=== Monitoramento de Status ==="
        echo "Selecione uma opção:"
        echo "1) Lista de Processos (atualizado a cada 1 segundo)"
        echo "2) Lista de Queries (atualizado a cada 1 segundo)"
        echo "0) Sair"

        read -p "Opção: " choice

        case $choice in
            1)
                show_process_list
                ;;
            2)
                show_query_list
                ;;
            0)
                echo "Saindo..."
                break
                ;;
            *)
                echo "Opção inválida. Por favor, tente novamente."
                show_status_monitoring_menu
                ;;
        esac
    done
}


adicionar_usuario() {
    echo "Digite o nome do usuário:"
    read -r nome_usuario

    echo "Gerando uma senha aleatória..."
    senha=$(generate_password 15 LUNS)
    echo "A senha gerada é: $senha"

    echo "Obtendo a lista de bancos de dados disponíveis..."
    lista_databases=($(obter_db_lista_databases))

    echo "Selecione o banco de dados para configurar os privilégios:"
    selecionar_opcao "${lista_databases[@]}"
    indice_database_selecionado=$?

    database_selecionado=${lista_databases[$indice_database_selecionado]}

    echo "Selecione o perfil do usuário:"
    selecionar_opcao "${DB_PERFIS[@]}"
    indice_perfil_selecionado=$?

    perfil_selecionado=${DB_PERFIS[$indice_perfil_selecionado]}
    privilegios_selecionados=${DB_PERFIS_PRIVILEGIOS[$indice_perfil_selecionado]}

    echo "Usuário: $nome_usuario"
    echo "Senha: $senha"
    echo "Banco de dados selecionado: $database_selecionado"
    echo "Perfil selecionado: $perfil_selecionado"

    # Aqui você pode realizar as configurações necessárias com as informações obtidas,
    # como criar o usuário, definir a senha e configurar os privilégios.

    echo "Usuário adicionado com sucesso!"
}


# Função para exibir o menu de gerenciamento de usuários
show_user_management_menu() {
  echo "=== Gerenciamento de Usuários ==="
  echo "1 - Listar todos usuários"
  echo "2 - Adicionar usuário"
  echo "3 - Alterar senha"
  echo "4 - Alterar permissão ao banco"
  echo "0 - Voltar"

  read -p "Escolha uma opção: " option
  case $option in
    1)
      echo "Listando todos usuários..."
      # Comando para listar todos usuários
      obter_db_lista_usuarios
      ;;
    2)
      read -p "Digite o nome do novo usuário: " username
      read -p "Digite o host do novo usuário [$HOST_DEFAULT]: " userhost
      userhost=${userhost:-$HOST_DEFAULT}
      password=$(generate_password 15 "LUNS")
      echo "Senha gerada para o usuário $username: $password"
      echo "Lista de bancos de dados disponíveis:"
      # Comando para listar bancos de dados
      read -p "Digite o banco de dados para conceder permissões [$PERMISSOES_DEFAULT]: " database
      database=${database:-$PERMISSOES_DEFAULT}
      echo "Permissões concedidas para o usuário $username no banco $database: $database"
      ;;
    3)
      echo "Lista de usuários:"
      # Comando para listar usuários
      read -p "Escolha um usuário para alterar a senha: " username
      echo "Regras da senha: ..."
      read -p "Digite a nova senha para o usuário $username: " new_password
      echo "Senha do usuário $username alterada com sucesso."
      ;;
    4)
      echo "Lista de bancos de dados:"
      # Comando para listar bancos de dados
      read -p "Escolha um banco de dados para alterar permissões: " database
      echo "Usuários com permissão ao banco $database:"
      # Comando para listar usuários com permissão ao banco
      echo "Deseja adicionar um novo usuário com permissão a este banco? (S/N)"
      read -p "Escolha uma opção: " add_user_option
      case $add_user_option in
        S | s)
          read -p "Digite o nome do novo usuário: " username
          read -p "Digite o host do novo usuário [$HOST_DEFAULT]: " userhost
          userhost=${userhost:-$HOST_DEFAULT}
          password=$(generate_password 15 "LUNS")
          echo "Senha gerada para o usuário $username: $password"
          echo "Permissões concedidas para o usuário $username no banco $database: $database"
          ;;
        N | n)
          echo "Nenhum usuário adicionado."
          ;;
        *)
          echo "Opção inválida"
          ;;
      esac
      ;;
    0)
      echo "Voltando..."
      ;;
    *)
      echo "Opção inválida"
      ;;
  esac
}

# https://blog.devops.dev/mysql-database-replication-master-slave-using-shell-script-bba720c82e38
replica() {
    echo
}

# Função para exibir o menu principal
main_menu() {
  echo "=== Menu Principal ==="
  echo "1 - Configuração"
  echo "2 - Selecionar Banco de Dados"
  echo "3 - Propriedades do Banco de Dados"
  echo "4 - Gerenciamento de Tabelas"
  echo "5 - Backup / Restauração"
  echo "6 - Status e Monitoramento"
  echo "7 - Gerenciamento de Usuários"
  echo "0 - Sair"

  read -p "Escolha uma opção: " option
  case $option in
    1)
      show_configuration_menu
      ;;
    2)
      show_database_menu
      ;;
    3)
      show_database_properties
      ;;
    4)
      show_table_management_menu
      ;;
    5)
      show_backup_restore_menu
      ;;
    6)
      show_status_monitoring_menu
      ;;
    7)
      show_user_management_menu
      ;;
    0)
      echo "Saindo..."
      return
      ;;
    *)
      echo "Opção inválida"
      ;;
  esac
}

mysql_cmd

mysql_prompt() {
    $MYSQL_CMD
}