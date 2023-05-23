#!/bin/bash
# 
# Version: 0.1  - 23/05/2023
#
# 
# Simples gerenciador do mysql/mariadb para bash, 
#   com opção de inserir,remover usuario, altear senha e permissões
#

Color_Off='\033[0m'       # Text Reset
BYellow='\033[1;33m'      # Yellow
IPurple='\033[0;95m'      # Purple

ARQUIVO_INI=.myini
HOST_DEFAULT='%'
MYSQL_ECHO=false
PERMISSOES_DEFAULT='SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES'
PERMISSOES_DISPONIVEIS="ALL PRIVILEGES, CREATE, DROP, SELECT, INSERT, UPDATE, DELETE, GRANT OPTION, ALTER, INDEX, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, SHOW VIEW, EVENT, TRIGGER"

# Se -v for adicionado aos argumentos, então o mysql será modo verboso

# Loop para percorrer os argumentos
for arg in "$@"; do
    if [ "$arg" = "-v" ]; then
        shift
        MYSQL_ECHO=true
        break
    fi
done
MYSQL_CMD="mysql -B -N -u root -h 127.0.0.1 -e "


echoColor() {
	echo -e "$Color_Off$1$Color_Off"
}

# $1 argumentos
mysql_cmd() {
    MYSQL_CMD="mysql $1 $2 $3 -B -N -e "
}
mysql_echo_and_run() {
    if [ "${MYSQL_ECHO}" = "true" ]; then
        echoColor "$BYellow""command>$IPurple $*" ; "$@" ; 
    else 
        "$@" ;
    fi
}

mysql_echo() {
    if [ "${MYSQL_ECHO}" = "true" ]; then
        echoColor "$BYellow""command>$IPurple $*" 
    fi
}


generate_password() {
  local length="${1:-8}"  # Tamanho mínimo da senha (padrão: 8)

  # Caracteres que serão usados para gerar a senha
  local characters="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_-+=<>?{}[]"

  # Obter o tamanho total da sequência de caracteres
  local characters_length=${#characters}

  local password=""

  # Loop para gerar cada caractere da senha
  for ((i=0; i<length; i++)); do
    # Gera um número aleatório entre 0 e (tamanho - 1)
    local random_index=$((RANDOM % characters_length))
    # Adiciona o caractere correspondente ao índice aleatório à senha
    password+="${characters:random_index:1}"
  done

  echo "$password"
}

# Função para ler o arquivo .myini
ler_arquivo_myini() {

    read -p "Digite o nome do arquivo (default: $ARQUIVO_INI): " arquivo
    arquivo=${arquivo:-$ARQUIVO_INI}

    if [ ! -f "$arquivo" ]; then
        echo "Arquivo $arquivo não encontrado."
        exit 1
    fi

    # Ler o arquivo .myini linha por linha
    while IFS='=' read -r chave valor; do
        if [[ -n $chave && ${chave:0:1} != "#" ]]; then
            case "$chave" in
                "usuario")
                    usuario="$valor"
                    ;;
                "host")
                    host="$valor"
                    ;;
                "senha")
                    senha="$valor"
                    ;;
                *)
                    echo "Chave inválida: $chave"
                    ;;
            esac
        fi
    done < "$arquivo"

    myargs=" -u $usuario"

    if [ ! -z "$host" ]; then
        myargs="$myargs -h $host"
    fi

    if [ ! -z "$senha" ]; then
        myargs="$myargs -p$senha"
    fi

    mysql_cmd "$myargs"
    echo $MYSQL_CMD;
}

# Função para ler os usuários e hosts do banco de dados
obter_usuarios() {
    usuarios=()
    hosts=()

    resultado=$($MYSQL_CMD 'SELECT User, Host FROM mysql.user WHERE User != "root" and User != "mariadb.sys" and User != "mysql"')

    # Ler o resultado e armazenar os usuários e hosts
    while IFS=$'\t' read -r usuario host; do
        usuarios+=("$usuario")
        hosts+=("$host")
    done <<< "$resultado"
}

# Função para exibir o menu de usuários
exibir_menu_usuarios() {
    for ((i = 0; i < ${#usuarios[@]}; i++)); do
        echo "$(($i + 1)). ${usuarios[$i]}@${hosts[$i]}"
    done
}

# Função para adicionar um usuário
adicionar_usuario() {
    echo "Digite o nome do novo usuário:"
    read novo_usuario

    read -p "Digite o host de acesso (default: $HOST_DEFAULT): " novo_host
    novo_host=${novo_host:-$HOST_DEFAULT}

    obter_bancos_dados
    exibir_menu_bancos_dados 
    read -p "Digite o número correspondente ao banco de dados: " selecao_banco

    if [[ $selecao_banco =~ ^[0-9]+$ && $selecao_banco -ge 1 && $selecao_banco -le ${#bancos_dados[@]} ]]; then
        novo_banco="${bancos_dados[$(($selecao_banco - 1))]}"

        read -p "Digite as permissões (default: $PERMISSOES_DEFAULT): " novo_permissoes
        novo_permissoes=${novo_permissoes:-$PERMISSOES_DEFAULT}

        # Gera uma nova senha aleatória
        password=$(generate_password 15)
        read -p "Digite uma senha (Gerada automaticamente: $password / Enter para aceitar): " nova_senha
        nova_senha=${nova_senha:-$password}

        mysql_echo_and_run $MYSQL_CMD "CREATE USER '$novo_usuario'@'$novo_host' IDENTIFIED BY '$nova_senha';"
        mysql_echo_and_run $MYSQL_CMD "GRANT $novo_permissoes ON $novo_banco.* TO '$novo_usuario'@'$novo_host';"
        mysql_echo_and_run $MYSQL_CMD "FLUSH PRIVILEGES;"

        echo "Usuário $novo_usuario adicionado com sucesso!"
    else
        echo "Seleção inválida."
    fi
}

# Função para deletar um usuário
deletar_usuario() {
    echo "Selecione o usuário para deletar:"
    obter_usuarios
    exibir_menu_usuarios
    read -p "Digite o número correspondente ao usuário: " selecao

    if [[ $selecao =~ ^[0-9]+$ && $selecao -ge 1 && $selecao -le ${#usuarios[@]} ]]; then
        usuario_deletar="${usuarios[$(($selecao - 1))]}"
        host_deletar="${hosts[$(($selecao - 1))]}"

        # Solicita confirmação do usuário antes de excluir o usuário
        read -p "Tem certeza de que deseja excluir o usuário '$usuario_deletar'@'$host_deletar'? (S/N): " confirm

        if [[ $confirm == "S" || $confirm == "s" ]]; then

            mysql_echo_and_run $MYSQL_CMD "DROP USER '$usuario_deletar'@'$host_deletar';"
            mysql_echo_and_run $MYSQL_CMD "FLUSH PRIVILEGES;"

            echo "Usuário $usuario_deletar deletado com sucesso!"
        else
            echo "Operação cancelada."
        fi
    else
        echo "Seleção inválida."
    fi
}

# Função para alterar a senha de um usuário
alterar_senha() {
    echo "Selecione o usuário para alterar a senha:"
    obter_usuarios
    exibir_menu_usuarios
    read -p "Digite o número correspondente ao usuário: " selecao

    if [[ $selecao =~ ^[0-9]+$ && $selecao -ge 1 && $selecao -le ${#usuarios[@]} ]]; then
        usuario_alterar="${usuarios[$(($selecao - 1))]}"
        host_alterar="${hosts[$(($selecao - 1))]}"

        # Gera uma nova senha aleatória
        password=$(generate_password 15)
        read -p "Digite uma senha (gerada automaticamente: $password / Enter para aceitar): " nova_senha
        nova_senha=${nova_senha:-$password}
        

        #mysql_echo_and_run $MYSQL_CMD "ALTER USER '$usuario_alterar'@'$host_alterar' IDENTIFIED BY '$nova_senha';"
        mysql_echo_and_run $MYSQL_CMD "SET PASSWORD FOR '$usuario_alterar'@'$host_alterar' = PASSWORD('$nova_senha');"
        mysql_echo_and_run $MYSQL_CMD "FLUSH PRIVILEGES;"

        echo "Senha do usuário $usuario_alterar alterada com sucesso!"
    else
        echo "Seleção inválida."
    fi
}

# Função para obter a lista de bancos de dados
obter_bancos_dados() {
    bancos_dados=()

    if [ -z "$1" && -z "$2" ] 
    then
        mysql_echo $MYSQL_CMD "\"SELECT DISTINCT Db FROM mysql.db WHERE User = '$1' AND Host = '$2';\""
        resultado=$($MYSQL_CMD "SELECT DISTINCT Db FROM mysql.db WHERE User = '$1' AND Host = '$2';")
    
    else
         mysql_echo $MYSQL_CMD "\"SELECT DISTINCT Db FROM mysql.db\""
        resultado=$($MYSQL_CMD "SELECT DISTINCT Db FROM mysql.db")   
    fi

    # Ler o resultado e armazenar os bancos de dados
    while IFS=$'\n' read -r banco_dados; do
        bancos_dados+=("$banco_dados")
    done <<< "$resultado"
}

# Função para exibir o menu de bancos de dados
exibir_menu_bancos_dados() {
    for ((i = 0; i < ${#bancos_dados[@]}; i++)); do
        echo "$(($i + 1)). ${bancos_dados[$i]}"
    done
}

obter_grants_do_usuario() 
{
    grants=()
    mysql_echo $MYSQL_CMD "SHOW GRANTS FOR '$1'@'$2';"

    resultado=$($MYSQL_CMD "SHOW GRANTS FOR '$1'@'$2'")

    # Ler o resultado e armazenar os bancos de dados
    while IFS=$'\n' read -r grants; do
        grants+=("$grants")
    done <<< "$resultado"
}

exibir_menu_de_grants() {
    for ((i = 1; i < ${#grants[@]}; i++)); do
        echo "$(($i + 1)). ${grants[$i]}"
    done
}

# Função para alterar as permissões de um usuário em um banco de dados
alterar_permissoes() {
    obter_usuarios
    echo "Selecione o usuário para alterar as permissões:"
    exibir_menu_usuarios
    read -p "Digite o número correspondente ao usuário: " selecao_usuario

    if [[ $selecao_usuario =~ ^[0-9]+$ && $selecao_usuario -ge 1 && $selecao_usuario -le ${#usuarios[@]} ]]; then
        usuario_alterar_perm="${usuarios[$(($selecao_usuario - 1))]}"
        host_alterar_perm="${hosts[$(($selecao_usuario - 1))]}"

        obter_bancos_dados $usuario_alterar_perm $host_alterar_perm
        echo "Selecione o banco de dados:"
        exibir_menu_bancos_dados 
        read -p "Digite o número correspondente ao banco de dados: " selecao_banco

        if [[ $selecao_banco =~ ^[0-9]+$ && $selecao_banco -ge 1 && $selecao_banco -le ${#bancos_dados[@]} ]]; then
            banco_alterar_perm="${bancos_dados[$(($selecao_banco - 1))]}"

            echo 
            echo "Possiveis permissões:"
            echo $PERMISSOES_DISPONIVEIS
            echo 
            obter_grants_do_usuario $usuario_alterar_perm $host_alterar_perm $banco_alterar_perm
            echo "Lista de Permissões de $usuario_alterar_perm @ $host_alterar_perm"
            exibir_menu_de_grants
            echo 

            read -p "Digite as novas permissões (default: $PERMISSOES_DEFAULT):" novas_permissoes
            novas_permissoes=${novas_permissoes:-$PERMISSOES_DEFAULT}

            mysql_echo_and_run $MYSQL_CMD "GRANT $novas_permissoes ON $banco_alterar_perm.* TO '$usuario_alterar_perm'@'$host_alterar_perm';"
            mysql_echo_and_run $MYSQL_CMD "FLUSH PRIVILEGES;"

            echo "Permissões do usuário $usuario_alterar_perm no banco $banco_alterar_perm alteradas com sucesso!"
        else
            echo "Seleção inválida."
        fi
    else
        echo "Seleção inválida."
    fi
}

# Função principal do script
main() {
    while true; do
        echo
        echo "Menu de Gerenciamento do MariaDB:"
        echo "---------------------------------"
        echo "1. Ler arquivo de dados .ini"
        echo "2. Adicionar usuário"
        echo "3. Deletar usuário"
        echo "4. Alterar senha do usuário"
        echo "5. Alterar permissões do usuário"
        echo "6. Listar Usuarios"
        echo "0. Sair"
        echo

        echo -n "Escolha uma opção: "
        read opcao
        echo

        case $opcao in
            1)
                ler_arquivo_myini
                ;;
            2)
                adicionar_usuario
                ;;
            3)
                deletar_usuario
                ;;
            4)
                alterar_senha
                ;;
            5)
                alterar_permissoes
                ;;
            6)
                obter_usuarios
                exibir_menu_usuarios
                ;;
            0)
                echo "Saindo do menu..."
                break
                ;;
            *)
                echo "Opção inválida. Tente novamente."
                ;;
        esac

        echo
        read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
        echo
    done
}

# Chamada da função principal
main
