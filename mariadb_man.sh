#!/bin/bash
################################################################
# Script: mariadb_man.sh
# Descrição: Gerenciador do banco de dados (Mariadb e Mysql)
# Autor: Candido H Tominaga <candido1212@gmail.com>
# Data: 2023-06-23
################################################################


# Variáveis globais

# No arquivo INI deve ser o seguinte formato
# [client]
# user=
# host=
# password=
ARQUIVO_INI=${1:-"~/.myini"} 

HOST_DEFAULT="%"

BACKUP_DIR=${2,-"/dados/backup"}

ECHO_CMD=false # se for true, todos os comandos serão impressos na tela e depois executados

ITEMS_FOR_CHECK=("FOR UPGRADE" "QUICK" "FAST" "MEDIUM" "EXTENDED" "CHANGED")
ITEMS_FOR_CHECKSUM=("QUICK" "EXTENDED")
ITEMS_FOR_DB_REPAIR=("QUICK" "EXTENDED" "USE_FRM")

DB_SELECTED="" # será usado para memorizar o banco de dados selecionado

ULTIMA_FUNCAO="" # Ultima funcao executada, para retorno do menu

# Array contendo todos os privilégios disponíveis
PRIVILEGIOS=(
    "ALL PRIVILEGES"          # Todos os privilégios possíveis
    "ALTER"                   # Permite alterar a estrutura de tabelas existentes
    "ALTER ROUTINE"           # Permite alterar rotinas existentes
    "CREATE"                  # Permite criar novos bancos de dados e tabelas
    "CREATE ROLE"             # Permite criar novos papéis de usuário
    "CREATE ROUTINE"          # Permite criar rotinas (procedimentos armazenados e funções)
    "CREATE TABLESPACE"       # Permite criar tablespaces
    "CREATE TEMPORARY TABLES" # Permite criar tabelas temporárias
    "CREATE USER"             # Permite criar novos usuários
    "CREATE VIEW"             # Permite criar novas views
    "DELETE"                  # Permite excluir registros de tabelas
    "DROP"                    # Permite excluir bancos de dados e tabelas
    "DROP ROLE"               # Permite excluir papéis de usuário
    "EVENT"                   # Permite criar, alterar e excluir eventos
    "EXECUTE"                 # Permite executar procedimentos armazenados e funções
    "FILE"                    # Permite acessar arquivos no servidor
    "GRANT ANY ROLE"          # Permite conceder qualquer papel de usuário a outros usuários
    "GRANT OPTION"            # Permite conceder privilégios a outros usuários
    "INDEX"                   # Permite criar índices em tabelas
    "INSERT"                  # Permite inserir novos registros em tabelas
    "LOCK TABLES"             # Permite bloquear tabelas para uso exclusivo
    "PROCESS"                 # Permite visualizar e matar processos de outros usuários
    "REFERENCES"              # Permite criar chaves estrangeiras em tabelas
    "RELOAD"                  # Permite recarregar configurações do servidor
    "REPLICATION CLIENT"      # Permite acessar informações sobre a replicação
    "REPLICATION SLAVE"       # Permite atuar como um slave em uma replicação de banco de dados
    "SELECT"                  # Permite realizar consultas (seleção) nos dados
    "SHOW DATABASES"          # Permite visualizar os bancos de dados disponíveis
    "SHOW VIEW"               # Permite visualizar a definição de views
    "SUPER"                   # Permite executar comandos com privilégios de superusuário
    "SHUTDOWN"                # Permite desligar o servidor do banco de dados
    "TRIGGER"                 # Permite criar, alterar e excluir gatilhos
    "UPDATE"                  # Permite atualizar registros existentes em tabelas
)

# Array contendo os perfis/administrative roles
DB_PERFIS=("DBA"
    "MaintenanceAdmin" # Direitos necessários para manter o servidor
    "ProcessAdmin"     # Direitos necessarios para monitorar, matar qualquer processos de usuários rodando no servidor
    "UserAdmin"        # Direitos para criar usuários e resetar senhas
    "SecurityAdmin"    # Direitos para gerenciar logins e conceder e revogar permissões de nível de servidor e banco de dados
    "MonitorAdmin"     # Permissões minimas para monitorar o servidor
    "DBManager"        # Concede direitos totais em todos os bancos de dados
    "DBDesigner"       # Direitos para criar e fazer engenharia reversa de qualquer esquema de banco de dados
    "ReplicationAdmin" # Direitos necessários para configurar e gerenciar a replicação
    "BackupAdmin"      # Direitos mínimos necessários para fazer backup de qualquer banco de dados
    "Wordpress"        # Permissões minimas para uso do wordpress e wp-cli
    "CRUD"             # Criar, Ler, Atualizar e Remover
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


# Função para imprimir os comandos executados em modo debug
echo_and_run() {
    if [ "${ECHO_CMD}" = "true" ]; then
        echoColor "$*" vermelho
        "$@"
    else
        "$@"
    fi
}

# Função flash_message, imprime as mensagens que estão no FLASH_MSG e zera
flash_message() {
    # Verifica se o array $FLASH_MSG está vazio
    if [ ${#FLASH_MSG[@]} -eq 0 ]; then
        return
    fi

    # Imprime todas as mensagens do array $FLASH_MSG
    for message in "${FLASH_MSG[@]}"; do
        echo "$message"
    done

    # Zera o array $FLASH_MSG
    unset FLASH_MSG
}

# adicionar uma flash_message
add_flash() {
    FLASH_MSG+=("$@")
}

# Função para pausar a execução e aguardar a entrada do usuário
pause() {
    local dummy
    read -s -r -p "$(echoColor 'Pressione qualquer tecla para continuar...' amarelo)"
    echo
}


# Função para exibir o menu numerado de um array, use: exibir_menu_from_array ${meu_array[@]}
exibir_menu_from_array() {
    local opcoes=$1
    for ((i=0; i<${#opcoes[@]}; i++)); do
        echo "$((i+1)). ${opcoes[$i]}"
    done
}

check_dependencias() {
    local missing_dependencies=()

    # Verifica se o comando 'mysql' está disponível
    if ! command -v mysql &>/dev/null; then
        missing_dependencies+=("mysql")
    fi

    # Verifica se o comando 'mysqldump' está disponível
    if ! command -v mysqldump &>/dev/null; then
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

# Função para gerar uma senha aleatória com parametros 1) tamanho 2) LUNS (L=lower,U=upper,N=Numeric,S=Special)
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

    for ((i = 0; i < length; i++)); do
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

# funcão que executa o ultimo menu
last_menu() {
    eval $LAST_MENU;
}

# funcão que vai imprimir a cor do texto
cores() {
    local color=$1
    # Cores de texto
    local red='\033[0;31m'
    local green='\033[0;32m'
    local yellow='\033[0;33m'
    local purple='\033[0;35m'
    local pink='\033[0;95m'
    local blue='\033[0;34m'
    local orange='\033[0;91m'
    local gray='\033[0;90m'
    local reset='\033[0m'

    # Verifica a cor fornecida e define o código de escape correspondente
    case "$color" in
        "verde")
            color=$green
            ;;
        "amarelo")
            color=$yellow
            ;;
        "violeta")
            color=$purple
            ;;
        "rosa")
            color=$pink
            ;;
        "azul")
            color=$blue
            ;;
        "laranja")
            color=$orange
            ;;
        "cinza")
            color=$gray
            ;;
        *)
            color=$red
            ;;
    esac
    echo "$color"
}

# Função para exibir uma mensagem formatada com cor
echoColor() {
    local reset='\033[0m'
    local message="$1"
    local color=$2
    local corTexto=$(cores $color)
    echo -e "${corTexto}${message}${reset}"
}

# Função para imprimir comand> $message com cor especificada
echoCmd() {
    local message=$1
    local color=${2:-"vermelho"}
    local comando=$(echoColor "Comando>" amarelo)
    local messageColor=$(echoColor "$message" $color)
    echo -e "$comando $messageColor $reset"
}

obter_db_lista_usuarios() {
    # Executa a consulta SQL para obter a lista de usuários
    local query="SELECT user FROM mysql.user WHERE USER NOT IN ('root')"

    # Executa o comando MySQL e retorna a lista de usuários
    $MYSQL_CMD -e "$query" -s -N
}

db_lista_usuarios_menu() {
    USUARIO_SELECIONADO=""
    local usuarios=()
    IFS=$'\n' read -r -d '' -a usuarios < <(obter_db_lista_usuarios)

    if [[ ${#usuarios[@]} -eq 0 ]]; then
        echo "Não há usuários disponíveis."
        pause
        last_menu
    else
        echo ""
        for ((i=0; i<"${#usuarios[@]}"; i++)); do
            echo "$((i+1)). ${usuarios[$i]}"
        done

        echo "Digite o número da lista de usuario:"
        read -r USUARIO_SELECIONADO

        # Verificar se o número do usuário é válido
        if [[ $USUARIO_SELECIONADO =~ ^[0-9]+$ && $USUARIO_SELECIONADO -ge 1 && $USUARIO_SELECIONADO -le "${#usuarios[@]}" ]]; then
            USUARIO_SELECIONADO="${usuarios[$usuario_selecionado - 1]}"
        else
            db_lista_usuarios_menu
        fi
    fi
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
        local privilegios=$(mysql -N -e "$query")

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
    clear
    local databases=$(obter_db_lista_databases)
    local db_count=0
    local selected_db=""

    echo "Selecione um banco de dados:"

    # Loop sobre a lista de bancos de dados e exibe o menu numerado
    while read -r db_name; do
        db_count=$((db_count + 1))
        echo "$db_count. $db_name"
    done <<<"$databases"

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

    add_flash "Banco de dados selecionado: $selected_db"
    main_menu
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
    LAST_MENU=$FUNCNAME;
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
    LAST_MENU=$FUNCNAME
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
    LAST_MENU=$FUNCNAME
    local choice

    while true; do
        clear
        flash_message
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
            main_menu
            break
            ;;
        *)
            add_flash "Você digitou uma opção inválida. Por favor, tente novamente."
            show_status_monitoring_menu
            ;;
        esac
    done
}

usuario_adicionar() {
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

usuario_alterar_senha() {
    echo "Escolha um usuario:"
    db_lista_usuarios_menu
    echo "Usuario selecionado: $USUARIO_SELECIONADO"
}

# Função para alterar privilégios do usuario para acesso ao banco de dados
db_alterar_privilegios() {
    echo
}

# Função para exibir o menu de gerenciamento de usuários
show_user_management_menu() {
    clear
    flash_message
    echo "=== Gerenciamento de Usuários ==="
    local menu=(
    "Listar (somente) todos usuários"
    "Adicionar usuário"
    "Alterar senha"
    "Alterar privilégios?"
    "Voltar")

    print_random_color_menu "${menu[@]}"

    read -p "Escolha uma opção: " option
    case $option in
    1)
        echo "Listando todos usuários..."
        # Comando para listar todos usuários
        obter_db_lista_usuarios
        pause
        show_user_management_menu
        ;;
    2)
        usuario_adicionar
        ;;
    3)
        usuario_alterar_senha
        ;;
    4)
        db_alterar_privilegios
        ;;
    5)
        main_menu
        ;;
    *)
        add_flash "Opção inválida"
        show_user_management_menu
        ;;
    esac
}

# https://blog.devops.dev/mysql-database-replication-master-slave-using-shell-script-bba720c82e38
replica() {
    echo
}

mysql_prompt() {
    clear
    $MYSQL_CMD
    main_menu
}

# Função para exibir o dashboard
dashboard() {
    echo "=== Informações do Banco de Dados ==="
    $MYSQL_CMD -e "SELECT VERSION() AS 'Versão do Banco de Dados', USER() AS 'Usuário Conectado'" -s

    echo "=== Lista de Databases e Tamanhos em Disco ==="
    local query="SELECT table_schema AS 'Database', SUM(data_length + index_length) / 1024 / 1024 AS 'Tamanho (MB)' FROM information_schema.tables GROUP BY table_schema"
    $MYSQL_CMD -e "$query" -s

    echo "=== Lista de Usuários e Databases ==="
    local query="SELECT DISTINCT user, GROUP_CONCAT(DISTINCT table_schema ORDER BY table_schema SEPARATOR ', ') AS 'Databases' FROM mysql.db GROUP BY user"
    $MYSQL_CMD -e "$query" -s

    pause
    main_menu
}

rainbow() {
    text=$1
    colors=("31" "32" "33" "34" "35" "36" "91" "92" "93" "94")
    num_colors=${#colors[@]}

    for (( i=0; i<${#text}; i++ )); do
        color_index=$((RANDOM % num_colors))
        color_code=${colors[color_index]}
        echo -en "\e[${color_code}m${text:$i:1}\e[0m"
    done

    echo
}

# Função para colorizar o SQL 
colorize_sql() {
    local sql="$1"
    local color_keyword=$(tput setaf 4)     # Azul
    local color_value=$(tput setaf 2)       # Verde
    local color_operator=$(tput setaf 3)    # Amarelo
    local color_reset=$(tput sgr0)          # Resetar formatação

    # Colorir palavras-chave
    sql=$(printf "%s" "$sql" | sed -E "s/(SELECT|FROM|WHERE|AND|OR)/${color_keyword}&${color_reset}/g")

    # Colorir valores de igualdades
    sql=$(printf "%s" "$sql" | sed -E "s/'([^']*)'/${color_value}'\1'${color_reset}/g")

    # Colorir operadores
    sql=$(printf "%s" "$sql" | sed -E "s/(!=|<=|>=|<|>|=|NOT IN|NOT)/${color_operator}&${color_reset}/g")

    printf "%s\n" "$sql"
}

# Função para imprimir o menu colorizado randomicamente
print_random_color_menu() {
    local menu=("$@")
    local colors=("\033[31m" "\033[32m" "\033[33m" "\033[34m" "\033[35m" "\033[36m" "\033[37m" "\033[38m")
    local num_colors=${#colors[@]}

    for ((i=0; i<${#menu[@]}; i++)); do
        local random_color_index=$((RANDOM % num_colors))
        local random_color="${colors[$random_color_index]}"
        local option="${menu[$i]}"
        local number=""

        if [ $# -ne 1 ] || [ $1 -ne 0 ]; then
            number="$((i+1)). "
        fi

        printf "${random_color}%s%s\033[0m\n" "$number" "$option"
    done
}


#!/bin/bash

# Função para imprimir a mensagem de copyright
print_copyright() {
    local year=$(date +%Y)
    local author="Candido H. Tominaga <candido1212@gmail.com>"
    local script_name="$0"

    printf "Copyright (C) %s %s\n" "$year" "$author"
    printf "Este programa é software livre: você pode redistribuí-lo e/ou modificá-lo\n"
    printf "sob os termos da Licença Pública Geral GNU, conforme publicada pela Free Software\n"
    printf "Foundation, na versão 3 da Licença, ou (a seu critério) qualquer versão posterior.\n"
    printf "Este programa é distribuído na esperança de que seja útil, mas SEM NENHUMA GARANTIA;\n"
    printf "sem uma garantia implícita de ADEQUAÇÃO a qualquer MERCADO ou APLICAÇÃO EM\n"
    printf "PARTICULAR. Consulte os detalhes da Licença Pública Geral GNU para obter mais\n"
    printf "informações.\n"
    printf "Você deve ter recebido uma cópia da Licença Pública Geral GNU junto com este\n"
    printf "programa. Se não, consulte <https://www.gnu.org/licenses/>.\n"
    printf "Nome do Script: %s\n" "$script_name"

}

# Função para exibir o menu principal
main_menu() {
    clear
    flash_message
    echo "=== Menu Principal ==="

    local menu=(
        "Dashboard" # 1
        "Selecionar Banco de Dados para ficar na memoria" # 2
        "Propriedades do Banco de Dados" #3
        "Gerenciamento de Tabelas: $DB_SELECTED" #4
        "Backup / Restauração" # 5
        "Status e Monitoramento" # 6
        "Gerenciamento de Usuários" #7
        "MySQL Prompt" #8
        "Sair" #9
    )
    print_random_color_menu "${menu[@]}"

    read -p "Escolha uma opção: " option
    case $option in
    1)
        dashboard
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
    8)
        mysql_prompt
        ;;
    9)
        echo "Saindo..."
        return
        ;;
    *)
        echo "Opção inválida"
        main_menu
        ;;
    esac
}

mysql_cmd

print_copyright
# main_menu

