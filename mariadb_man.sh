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
    "EVENT, LOCK TABLES, SELECT, RELOAD, PROCESS"
    # Privilégios para o perfil "Wordpress"
    "SELECT, SHOW VIEW, ALTER, ALTER ROUTINE, CREATE, CREATE ROUTINE, CREATE TEMPORARY TABLES, CREATE VIEW, DELETE, DROP, INDEX, INSERT, TRIGGER, UPDATE, LOCK TABLES"
    # Privilégios para o perfil "CRUD"
    "SELECT, INSERT, UPDATE, DELETE"
)


############### Funcoes Uteis ################

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

# Função para pause a execução e aguardar a entrada do usuário
pause() {
    local dummy
    read -s -r -p "$(echoColor 'Pressione qualquer tecla para continuar...' amarelo)"
    echo
}


# Função para exibir o menu numerado de um array, use: show_menu_menu_from_array ${meu_array[@]}
show_menu_menu_from_array() {
    local opcoes=$1
    for ((i=0; i<${#opcoes[@]}; i++)); do
        echoColor "$((i+1)). ${opcoes[$i]}" `color_rand`
    done
}

check_dependencies() {
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
        echoColor "As seguintes dependências estão ausentes:" vermelho
        for dependency in "${missing_dependencies[@]}"; do
            echoColor " - $dependency" azul
        done
        echo "";
        return
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
    MYSQL_CMD="$(which mysql) --defaults-file=$ARQUIVO_INI"
}

# funcão que executa o ultimo menu
last_menu() {
    eval $LAST_MENU;
}

# retorna uma cor do array (usadas as mesmos cores da funcao color_text())
color_rand() {
    local colors=(verde amarelo violeta rosa azul laranja cinza)
    echo ${colors[$RANDOM % ${#colors[@]}]}
}


test_mysql_connection() {
    mysql_cmd

    local result=$($MYSQL_CMD -e "SELECT 1;" 2>&1)
    
    if [[ -e $ARQUIVO_INI ]]; then
        echoColor "Arquivo $(realpath "$ARQUIVO_INI") existe." amarelo
    else
        echoColor "Arquivo $ARQUIVO_INI não existe." vermelho
    fi
    
    if [[ $result == *"ERROR"* ]]; then
        echoColor "Não foi possível conectar ao MySQL. Verifique suas credenciais e certifique-se de que o servidor esteja em execução." vermelho
    else
        echoColor "Conexão com o MySQL estabelecida com sucesso." verde
    fi
}



# funcão que vai imprimir a cor do texto
color_text() {
    local color=$1
    # color_text de texto
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
    local corTexto=$(color_text $color)
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

voltar() {
    local funcaoVoltar=$1
    echo ""
    echoColor "Menu: " rosa
    echoColor "1) Sair do script" vermelho
    echoColor "2) Voltar" cinza
    echoColor "3) Continuar"  verde

    read -p "Escolha uma opção: " opcao

    case $opcao in
        1)
            # Matar o processo do próprio script
            kill -INT $$
            ;;
        2)
            $funcaoVoltar ;; # Executa a função passada como parâmetro
        3)
            return ;; # continuar
        *)
            echo "Opção inválida." 
            voltar "$1"
            ;;
    esac
}

# Texto colorido
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
print_random_color_for_menu() {
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


######### Gerencia de Usuarios #########

user_list() {
    # Executa a consulta SQL para obter a lista de usuários
    local query="SELECT concat(USER,'@',HOST) FROM mysql.user WHERE USER NOT IN ('root')"

    # Executa o comando MySQL e retorna a lista de usuários
    $MYSQL_CMD -e "$query" -s -N
}

user_menu_list_of_users() {
    USUARIO_SELECIONADO=""
    local usuarios=()
    IFS=$'\n' read -r -d '' -a usuarios < <(user_list)

    if [[ ${#usuarios[@]} -eq 0 ]]; then
        echoColor "Não há usuários disponíveis." amarelo
        pause
        last_menu
    else
        echo ""
        for ((i=0; i<"${#usuarios[@]}"; i++)); do
            echoColor "$((i+1)). ${usuarios[$i]}" `color_rand`
        done

        echo 
        printf "Digite o número da lista de usuario: "
        read -r USUARIO_SELECIONADO

        # Verificar se o número do usuário é válido
        if [[ $USUARIO_SELECIONADO =~ ^[0-9]+$ && $USUARIO_SELECIONADO -ge 1 && $USUARIO_SELECIONADO -le "${#usuarios[@]}" ]]; then
            USUARIO_SELECIONADO="${usuarios[$USUARIO_SELECIONADO - 1]}"
            
        else
            add_flash "Opção escolhida não é válida"
            user_menu_list_of_users
        fi
    fi
}



user_add() {
    echo "Digite o nome do usuário:"
    read -r nome_usuario

    # Gerar uma senha sugestão usando a função generate_password
    senha=$(generate_password 15 LUNS)
    echoColor "Sugestão de senha: $senha" violeta

    # Solicitar a senha e confirmá-la
    while true; do
        echoColor "Digite a senha (ou pressione Enter para usar a sugestão):" amerelo
        read -r -s -n 1 senha_digitada
        if [[ -z "$senha_digitada" ]]; then
            break
        fi
        senha+="$senha_digitada"
    done

    read -p "Digite o nome do host de acesso (padrão: $HOST_DEFAULT): " new_host
    new_host=${new_host:-$HOST_DEFAULT}


    # Obter a lista de bancos de dados
    lista_databases=($(db_get_all_databases))

    # Apresentar a lista de bancos de dados como menu numerado
    echoColor "Selecione o banco de dados:" violeta
    for ((i=0; i<"${#lista_databases[@]}"; i++)); do
        echo "$((i+1)). ${lista_databases[$i]}"
    done

    local db_selecionado
    read -r db_selecionado

    # Verificar se o número do banco de dados é válido
    if [[ $db_selecionado =~ ^[0-9]+$ && $db_selecionado -ge 1 && $db_selecionado -le "${#lista_databases[@]}" ]]; then
        db_selecionado="${lista_databases[$db_selecionado - 1]}"

        # Solicitar o perfil de usuário
        echo "Selecione o perfil do usuário:"
        for ((i=0; i<"${#DB_PERFIS[@]}"; i++)); do
            echo "$((i+1)). ${DB_PERFIS[$i]}"
        done

        read -r perfil_usuario

        # Verificar se o número do perfil é válido
        if [[ $perfil_usuario =~ ^[0-9]+$ && $perfil_usuario -ge 1 && $perfil_usuario -le "${#DB_PERFIS[@]}" ]]; then
            perfil_usuario_nome="${DB_PERFIS[$perfil_usuario - 1]}"

            # Obter os privilégios associados ao perfil selecionado
            local privilegios_usuario="${DB_PERFIS_PRIVILEGIOS[$perfil_usuario - 1]}"

            # Criar o usuário com os privilégios associados ao perfil no banco de dados selecionado
            local query="CREATE USER '${nome_usuario}'@'${new_host}' IDENTIFIED BY '${senha}';"
            query+="GRANT ${privilegios_usuario} ON ${db_selecionado}.* TO '${nome_usuario}'@'${new_host}';"
            query+="FLUSH PRIVILEGES;"
            $MYSQL_CMD -e "$query"

            echo "Usuário ${nome_usuario} adicionado com sucesso com os privilégios: ${privilegios_usuario}"
        else
            echo "Número de perfil inválido."
        fi
    else
        echo "Número de banco de dados inválido."
    fi
    pause
    show_menu_user_management
}

user_alter_password() {
    clear
    flash_message
    echoColor "Escolha um usuário para alterar a senha:" violeta
    USUARIO_SELECIONADO=""
    user_menu_list_of_users
    echo "Usuário selecionado: $USUARIO_SELECIONADO"
    echo

    if [ -z "$USUARIO_SELECIONADO" ]; then
        echo "Nenhum usuário selecionado. Saindo..."
        return
    fi

    local senha_sugerida
    senha_sugerida=$(generate_password 15 LUNS)
    local usar_senha_sugerida=true

    read -p "Deseja usar a senha sugerida '$senha_sugerida'? (S/N): " resposta
    resposta=${resposta^^} # Converter a resposta para maiúsculas

    if [ "$resposta" = "N" ]; then
        usar_senha_sugerida=false
    fi

    local senha

    if [ "$usar_senha_sugerida" = true ]; then
        senha=$senha_sugerida
    else
        read -sp "Digite a nova senha: " senha
        echo
    fi

    read -sp "Confirme a nova senha: " confirmacao
    echo

    if [ "$senha" != "$confirmacao" ]; then
        echo "As senhas não correspondem. Saindo..."
        return
    fi

    echo "Alterando a senha do usuário '$USUARIO_SELECIONADO'..."
    # Lógica para alterar a senha do usuário no banco de dados
    # ...

    echo "Senha do usuário '$USUARIO_SELECIONADO' alterada com sucesso."
}


user_drop() {
    echo
    echo "=== Remover Usuário ==="
    echo

    USUARIO_SELECIONADO=""
    local usuarios=()
    IFS=$'\n' read -r -d '' -a usuarios < <(user_list)

    if [[ ${#usuarios[@]} -eq 0 ]]; then
        echoColor "Não há usuários disponíveis para remover." verde
        pause
        show_menu_user_management
    else
        echo "Selecione o número correspondente ao usuário que deseja remover:"
        for ((i=0; i<"${#usuarios[@]}"; i++)); do
            echo "$((i+1)). ${usuarios[$i]}"
        done

        local usuario_selecionado
        read -r usuario_selecionado

        if [[ $usuario_selecionado =~ ^[0-9]+$ && $usuario_selecionado -ge 1 && $usuario_selecionado -le "${#usuarios[@]}" ]]; then
            local nome_usuario="${usuarios[$usuario_selecionado - 1]}"

            echo "Deseja remover o usuário '$nome_usuario'? (S/N)"
            read -r confirmacao

            if [[ $confirmacao =~ ^[Ss]$ ]]; then
                # Remover o usuário do banco de dados
                local nome_usuario_host="'${nome_usuario//@/\''@'\'}'"
                local query="DROP USER ${nome_usuario_host};"
                $MYSQL_CMD -e "$query"

                echo "Usuário '$nome_usuario' removido com sucesso."
            else
                echo "Operação de remoção de usuário cancelada."
            fi
        else
            echo "Opção inválida. Por favor, selecione um número válido."
            user_drop
        fi
    fi

    pause
    show_menu_user_management
}

user_get_all_privileges() {
    echo
    echo "=== Obter todos os privilégios do usuário ==="
    echo

    local usuarios=()
    IFS=$'\n' read -r -d '' -a usuarios < <(user_list)

    if [[ ${#usuarios[@]} -eq 0 ]]; then
        echoColor "Não há usuários disponíveis." verde
        pause
        show_menu_user_management
    else
        echo "Selecione o número correspondente ao usuário:"
        for ((i=0; i<"${#usuarios[@]}"; i++)); do
            echo "$((i+1)). ${usuarios[$i]}"
        done

        local usuario_selecionado
        read -r usuario_selecionado

        if [[ $usuario_selecionado =~ ^[0-9]+$ && $usuario_selecionado -ge 1 && $usuario_selecionado -le "${#usuarios[@]}" ]]; then
            local nome_usuario="${usuarios[$usuario_selecionado - 1]}"
            local nome_usuario_host="'${nome_usuario//@/\''@'\'}'"
            local query="SHOW GRANTS FOR ${nome_usuario_host};"
            local resultado=$($MYSQL_CMD -e "$query")

            if [[ -n $resultado ]]; then
                echo
                echo "Privilégios do usuário '$nome_usuario':"
                echo "$resultado"

                voltar user_get_all_privileges
            else
                echoColor "Não foi possível obter os privilégios do usuário '$nome_usuario'." vermelho
            fi
        else
            echo "Opção inválida. Por favor, selecione um número válido."
            user_get_all_privileges
        fi
    fi

    pause
    show_menu_user_management
}

######### Gerencia de Banco de Dados #########

db_get_all_databases() {
    # Executa a consulta SQL para obter a lista de bancos de dados
    local query="SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME NOT IN ('information_schema','performance_schema')"

    # Executa o comando MySQL e retorna a lista de bancos de dados
    $MYSQL_CMD -e "$query" -s -N
}

db_create_database() {
    echo "Digite o nome do banco de dados:"
    read -r nome_banco_dados

    # Verificar se o nome do banco de dados é válido
    if [[ -z "$nome_banco_dados" ]]; then
        echo "Nome do banco de dados inválido. Saindo..."
        pause
        show_menu_database_management
        return
    fi

    # Verificar se o banco de dados já existe
    local query="SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME = '$nome_banco_dados'"
    local resultado=$($MYSQL_CMD -e "$query" -s -N)

    if [[ -n "$resultado" ]]; then
        echo "O banco de dados '$nome_banco_dados' já existe. Saindo..."
        pause
        show_menu_database_management
        return
    fi

    # Criar o banco de dados
    query="CREATE DATABASE $nome_banco_dados"
    $MYSQL_CMD -e "$query"

    echo "Database '$nome_banco_dados' criado com sucesso"
    pause
    show_menu_database_management
}


db_drop_database() {
    local db_name=$1
    $MYSQL_CMD -s -N -e "DROP DATABASE IF NOT EXISTS $db_name;"
    echo "Database '$db_name' removido com sucesso" 
}
# Função para alterar privilégios do usuario para acesso ao banco de dados
db_alter_privileges() {
    echo "Selecione uma opção para alterar os privilégios:"
    echo "1) Privilégios globais"
    echo "2) Privilégios por banco de dados"
    echo

    local opcao
    read -p "Digite o número da opção desejada: " opcao
    echo

    case "$opcao" in
        1)
            echo "Você selecionou alterar os privilégios globais."
            local usuario
            read -p "Digite o nome do usuário: " usuario
            echo

            # Verificar se o usuário existe
            local usuario_existe=false
            for db_usuario in "${USUARIOS[@]}"; do
                if [ "$db_usuario" = "$usuario" ]; then
                    usuario_existe=true
                    break
                fi
            done

            if [ "$usuario_existe" = false ]; then
                echo "Usuário '$usuario' não encontrado. Saindo..."
                return
            fi

            # Lógica para alterar os privilégios globais do usuário especificado
            echo "Digite os privilégios separados por vírgula (exemplo: SELECT,INSERT,UPDATE):"
            read -p "Privilégios: " privilegios
            echo

            echo "Alterando os privilégios globais do usuário '$usuario' para: $privilegios"
            # Lógica para realizar a alteração dos privilégios globais
            # ...

            ;;
        2)
            echo "Você selecionou alterar os privilégios por banco de dados."
            local usuario
            read -p "Digite o nome do usuário: " usuario
            echo

            # Verificar se o usuário existe
            local usuario_existe=false
            for db_usuario in "${USUARIOS[@]}"; do
                if [ "$db_usuario" = "$usuario" ]; then
                    usuario_existe=true
                    break
                fi
            done

            if [ "$usuario_existe" = false ]; then
                echo "Usuário '$usuario' não encontrado. Saindo..."
                return
            fi

            local banco_dados
            read -p "Digite o nome do banco de dados: " banco_dados
            echo

            # Verificar se o banco de dados existe
            local banco_dados_existe=false
            for db_banco_dados in "${DATABASES[@]}"; do
                if [ "$db_banco_dados" = "$banco_dados" ]; then
                    banco_dados_existe=true
                    break
                fi
            done

            if [ "$banco_dados_existe" = false ]; then
                echo "Banco de dados '$banco_dados' não encontrado. Saindo..."
                return
            fi

            # Lógica para alterar os privilégios do usuário especificado para o banco de dados especificado
            echo "Digite os privilégios separados por vírgula (exemplo: SELECT,INSERT,UPDATE):"
            read -p "Privilégios: " privilegios
            echo

            echo "Alterando os privilégios do usuário '$usuario' para o banco de dados '$banco_dados' para: $privilegios"
            # Lógica para realizar a alteração dos privilégios por banco de dados
            # ...

            ;;
        *)
            echo "Opção inválida. Saindo..."
            return
            ;;
    esac

    # Restante da lógica da função...
    # Você pode adicionar aqui as etapas adicionais para configurar os privilégios, etc.
}

# Função para exibir as propriedades de um banco de dados selecionado
db_database_properties() {
    local query="SELECT * FROM information_schema.SCHEMATA"
    clear
    $MYSQL_CMD -e "$query"
    pause
    show_menu_database_management
}

db_list_without_users_privileges() {
    # Consulta SQL para obter a lista de bancos de dados sem privilégios para usuários
    local query="
        SELECT DISTINCT db.SCHEMA_NAME
        FROM information_schema.SCHEMATA AS db
        LEFT JOIN (
            SELECT Db
            FROM mysql.db
            WHERE User != 'root'
        ) AS priv_users ON db.SCHEMA_NAME = priv_users.Db
        WHERE db.SCHEMA_NAME NOT IN ('mysql', 'information_schema', 'performance_schema', 'sys')
            AND priv_users.Db IS NULL;
    "

    # Executa o comando MySQL e retorna a lista de bancos de dados sem privilégios para usuários
    $MYSQL_CMD -e "$query" -N
    pause
    show_menu_database_management
}


######## Tabelas ############

tb_get_all_tables() {
    local database_name=$1
    local query="SHOW TABLES FROM $database_name;"
    # Executa o comando MySQL e retorna a lista
    $MYSQL_CMD -e "$query" -s -N
}

# Função para checar tabelas
tb_check_tables() {
    local database=$1
    local tabela=$2
    # Comando para checar tabelas
    $MYSQL_CMD $database -e "CHECK TABLE $tabela;"
}

# Função para analisar tabelas
tb_analyze_tables() {
    local database=$1
    local tabela=$2
    # Comando para analisar tabelas
    $MYSQL_CMD $database -e "ANALYZE TABLE $tabela;"
}

# Função para calcular checksum das tabelas
tb_calculate_checksum() {
    local database=$1
    local tabela=$2
    # Comando para calcular checksum das tabelas
    $MYSQL_CMD $database -e "CHECKSUM TABLE $tabela;"
}

# Função para otimizar tabelas
tb_optimize_tables() {
    local database=$1
    local tabela=$2
    # Comando para otimizar tabelas
    $MYSQL_CMD $database -e "OPTIMIZE TABLE $tabela;"
}

# Função para reparar tabelas
tb_repair_tables() {
    local database=$1
    local tabela=$2
    # Comando para reparar tabelas
    $MYSQL_CMD $database -e "REPAIR TABLE nome_tabela;"
}

tb_loop_all_tables() {
    local exec_func=$1
    local database=$2
    local tabelas=()

    while IFS= read -r line; do
        tabelas+=("$line")
    done < <(tb_get_all_tables $database)

    lista=$(IFS=, ; echo "${tabelas[*]}")

    $exec_func $database $lista
}

######### Menus #########################

show_menu_database() {
    clear
    local databases=$(db_get_all_databases)
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
        show_menu_database
    fi

    add_flash "Banco de dados selecionado: $selected_db"
    menu_main
}

show_menu_database_management() {
    clear
    flash_message
    echo "=== Gerenciamento de Banco de Dados ==="
    local menu=(
        "Listar todos os bancos de dados"
        "Criar Banco de Dados"
        "Deletar Banco de Dados"
        "Listar propriedades de todos os bancos de dados"
        "Listar Banco de dados que não tenha usuarios com privilégios"
        "Voltar"
    )
    print_random_color_for_menu "${menu[@]}"

    read -p "Escolha uma opção: " option
    case $option in
        1)
            local databases=($(db_get_all_databases))
            echo "Lista de bancos de dados:"
            for ((i=0; i<"${#databases[@]}"; i++)); do
                echo "$((i+1)). ${databases[$i]}"
            done
            pause
            show_menu_database_management
            ;;
        2)
            db_create_database
            ;;
        3)
            db_drop_database
            ;;
        4)
            db_database_properties
            ;;
        5)
            db_list_without_users_privileges
            ;;
        6)
            menu_main
            ;;
        *)
            add_flash "Opção inválida"
            show_menu_database_management
            ;;
    esac
}




# Função para exibir o menu de gerenciamento de tabelas
show_menu_table_management() {
    clear
    LAST_MENU=$FUNCNAME;
    if [ -z "$DB_SELECTED" ]; then
        echo "Nenhum banco de dados selecionado."
        pause
        show_menu_database
    fi

    echoColor "=== Gerenciamento de Tabelas de [$DB_SELECTED] ===" violeta

    local menu=(
        "Checar"
        "Analisar"
        "Checksum"
        "Otimizar"
        "Reparar"
        "Voltar"
    )

    print_random_color_for_menu "${menu[@]}"  

    read -p "Escolha uma opção: " option
    case $option in
    1)
        echo "Checando tabelas..."
        tb_loop_all_tables tb_check_tables $DB_SELECTED
        pause
        show_menu_table_management
        ;;
    2)
        echo "Analisando tabelas..."
        tb_loop_all_tables tb_analyze_tables $DB_SELECTED
        pause
        show_menu_table_management
        ;;
    3)
        echo "Calculando checksum das tabelas..."
        tb_loop_all_tables tb_calculate_checksum $DB_SELECTED
        pause
        show_menu_table_management
        ;;
    4)
        echo "Otimizando tabelas..."
        tb_loop_all_tables tb_optimize_tables $DB_SELECTED
        pause
        show_menu_table_management
        ;;
    5)
        echo "Reparando tabelas..."
        tb_loop_all_tables tb_repair_tables $DB_SELECTED
        pause
        show_menu_table_management
        ;;
    6)
        echo "Voltando..."
        menu_main
        ;;
    *)
        echo "Opção inválida"
        pause
        show_menu_table_management
        ;;
    esac
}

# Função para exibir o menu de backup/restauração
show_menu_backup_restore() {
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

show_menu_process_list() {
    while true; do
        clear
        echo "=== Lista de Processos ==="
        $MYSQL_CMD -e "SHOW FULL PROCESSLIST;"

        echo "Pressione qualquer tecla para sair..."

        read -t 1 -n 1
        if [ $? = 0 ]; then
            show_menu_status_monitoring
            break
        fi

    done
}

show_menu_query_list() {
    while true; do
        clear
        echo "=== Lista de Queries ==="
        $MYSQL_CMD -e "SHOW FULL PROCESSLIST\G"

        echo "Pressione qualquer tecla para sair..."

        read -t 1 -n 1
        if [ $? = 0 ]; then
            show_menu_status_monitoring
            break
        fi
    done
}


# Função para exibir o menu de status e monitoramento
show_menu_status_monitoring() {
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
            show_menu_process_list
            ;;
        2)
            show_menu_query_list
            ;;
        0)
            menu_main
            break
            ;;
        *)
            add_flash "Você digitou uma opção inválida. Por favor, tente novamente."
            show_menu_status_monitoring
            ;;
        esac
    done
}



# Função para exibir o menu de gerenciamento de usuários
show_menu_user_management() {
    clear
    flash_message
    echo "=== Gerenciamento de Usuários ==="
    local menu=(
    "Listar (somente) todos usuários"
    "Adicionar usuário"
    "Alterar senha"
    "Deletar usuário"
    "Alterar privilégios?"
    "Voltar")

    print_random_color_for_menu "${menu[@]}"

    read -p "Escolha uma opção: " option
    case $option in
    1)
        clear
        echo "Listando todos usuários..."
        # Comando para listar todos usuários
        user_list
        pause
        show_menu_user_management
        ;;
    2)
        user_add
        ;;
    3)
        user_alter_password
        ;;
    4)
        user_drop
        ;;
    5)
        db_alter_privileges
        ;;
    6)
        menu_main
        ;;
    *)
        add_flash "Opção inválida"
        show_menu_user_management
        ;;
    esac
}

######## Funcoes para Backup e Outros ###########

# Função para fazer backup físico
backup_perform_physical() {
    echo "Realizando backup físico..."
    local dmahms=$(date +"%Y-%m-%d_%H%M%S")
    local diretorio="/dados/backup"

    mariabackup --defaults-file=/root/.myini -V --compress --backup --target-dir="/$diretorio/$dmahms"

}

# Função para fazer backup lógico
backup_perform_logical() {
    echo "Realizando backup lógico..."
    # Comando para fazer backup lógico
    # Substitua as variáveis a seguir pelos valores apropriados
    local backup_dir="/caminho/para/backup"
    local backup_file="nome_backup.sql"
    $MYSQL_CMD -e "mysqldump nome_banco_de_dados > '$backup_dir/$backup_file';"
}


# Mysql database replication — master/slave using shell script
replication() {
    clear
    echo "Abra o endereço:"
    echo "https://blog.devops.dev/mysql-database-replication-master-slave-using-shell-script-bba720c82e38"
    echo
    pause
    menu_main
}

# Para entrar no prompt do mysql
mysql_prompt() {
    clear
    $MYSQL_CMD
    menu_main
}

# Função para exibir o dashboard
dashboard() {
    clear
    echoColor "=== Informações do Banco de Dados ===" violeta
    $MYSQL_CMD -e "SELECT VERSION() AS 'Versão do Banco de Dados', USER() AS 'Usuário Conectado'"

    echoColor "=== Lista de Databases e Tamanhos em Disco ===" violeta
    local query="SELECT table_schema AS 'Database', ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Tamanho (MB)' FROM information_schema.tables GROUP BY table_schema"
    $MYSQL_CMD -e "$query"

    echoColor "=== Lista de Usuários e Databases ===" violeta
    local query="SELECT DISTINCT user, GROUP_CONCAT(DISTINCT db ORDER BY db SEPARATOR ', ') AS 'Databases' FROM mysql.db GROUP BY user"
    $MYSQL_CMD -e "$query"

    pause
    menu_main
}

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
    printf "programa. Se não, consulte <https://www.gnu.org/licenses/>.\n\n"
    printf "Nome do Script: %s\n" "$script_name"
    printf "\n"

}

# Função para exibir o menu principal
menu_main() {
    clear
    flash_message
    echo "=== Menu Principal ==="

    local menu=(
        "Dashboard" # 1
        "Selecionar Banco de Dados (ficara na memoria)" # 2
        "Gerenciamento de Databases" # 3
        "Gerenciamento das Tabelas do DB: [$DB_SELECTED]" #4
        "Backup / Restauração" # 5
        "Status e Monitoramento" # 6
        "Gerenciamento de Usuários" #7
        "MySQL Prompt" #8
        "Replicação" #9
        "Sair" #10
    )
    print_random_color_for_menu "${menu[@]}"

    read -p "Escolha uma opção: " option
    case $option in
    1)
        dashboard
        ;;
    2)
        show_menu_database
        ;;
    3)
        show_menu_database_management
        ;;
    4)
        show_menu_table_management
        ;;
    5)
        show_menu_backup_restore
        ;;
    6)
        show_menu_status_monitoring
        ;;
    7)
        show_menu_user_management
        ;;
    8)
        mysql_prompt
        ;;
    9)
        replication
        ;;

    10)
        echo "Saindo..."
        return
        ;;
    *)
        echo "Opção inválida"
        menu_main
        ;;
    esac
}

mysql_cmd
test_mysql_connection
#print_copyright
#check_dependencies
#pause
#menu_main

