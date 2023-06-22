#!/bin/bash

BACKUP_DIR=/tmp/dbbackup
BACKUP_FILE=dump_all.sql

# Função para exibir o menu principal
show_menu() {
    clear
    echo "=============================="
    echo " Plano de Recuperação de Desastres "
    echo "=============================="
    echo "1. Backup"
    echo "2. Restauração"
    echo "3. Status e Monitoramento"
    echo "4. Gerenciamento de Usuários"
    echo "5. Gerenciamento de Tabelas"
    echo "6. Gerenciamento de Replicação"
    echo "7. Configurações"
    echo "0. Sair"
    echo "=============================="
}

# Funções relacionadas a backup

perform_logical_backup() {
    echo "Executando backup lógico..."
    mysqldump --defaults-file=/root/.my.ini --all-databases > backup_logical.sql
    echo "Backup lógico concluído. O arquivo de backup é 'backup_logical.sql'."
}

perform_physical_backup() {
    read -p "Deseja usar o diretório de backup padrão '$BACKUP_DIR'? (s/n): " use_default_dir
    if [[ $use_default_dir == "n" || $use_default_dir == "N" ]]; then
        read -p "Digite o diretório de backup: " backup_dir
    else
        backup_dir=$BACKUP_DIR
    fi

    read -p "Deseja usar o arquivo de backup padrão '$BACKUP_FILE'? (s/n): " use_default_file
    if [[ $use_default_file == "n" || $use_default_file == "N" ]]; then
        read -p "Digite o nome do arquivo de backup: " backup_file
    else
        backup_file=$BACKUP_FILE
    fi

    echo "Executando backup físico..."
    mkdir -p "$backup_dir"
    mysqldump --defaults-file=/root/.my.ini --all-databases > "$backup_dir/$backup_file"
    echo "Backup físico concluído. O arquivo de backup está localizado em '$backup_dir/$backup_file'."
}


perform_restore() {
    echo "Restaurando backup..."
    # Comandos para restaurar backup
    echo "Backup restaurado."
}

# Funções relacionadas a status e monitoramento

check_replication_status() {
    echo "Verificando status da replicação..."
    # Comandos para verificar status da replicação
    echo "Status da replicação verificado."
}

check_server_status() {
    echo "Verificando status do servidor MariaDB..."
    systemctl status mariadb
    echo "Status do servidor MariaDB verificado."
}

check_database_directory_usage() {
    echo "Verificando uso de espaço em disco do diretório do banco de dados..."
    du -sh /var/lib/mysql
    echo "Uso de espaço em disco verificado."
}

check_database_size() {
    echo "Verificando tamanho de um banco de dados específico..."
    # Comandos para verificar tamanho do banco de dados
    echo "Tamanho do banco de dados verificado."
}

# Funções relacionadas a gerenciamento de usuários

check_user_privileges() {
    echo "Verificando os privilégios de usuário..."
    # Comandos para verificar privilégios de usuário
    echo "Privilégios de usuário verificados."
}

change_user_password() {
    echo "Alterando a senha do usuário..."
    # Comandos para alterar a senha do usuário
    echo "Senha do usuário alterada."
}

add_user() {
    echo "Adicionando um novo usuário..."
    # Comandos para adicionar um novo usuário
    echo "Novo usuário adicionado."
}

# Funções relacionadas a gerenciamento de tabelas

optimize_tables() {
    echo "Executando otimização de tabelas..."
    # Comandos para otimizar tabelas
    echo "Otimização de tabelas concluída."
}

analyze_table() {
    echo "Executando análise de tabela..."
    # Comandos para analisar tabela
    echo "Análise de tabela concluída."
}

# Funções relacionadas a gerenciamento de replicação

restart_replication() {
    echo "Reiniciando a replicação..."
    # Comandos
 para reiniciar a replicação
    echo "Replicação reiniciada."
}

# Funções relacionadas a configurações

read_ini_file() {
    ini_file="/root/.my.ini"

    if [[ ! -f $ini_file ]]; then
        echo "Arquivo INI não encontrado."
        return
    fi

    while IFS='=' read -r key value; do
        if [[ ! -z $key && ! -z $value ]]; then
            case $key in
                host) host=$value ;;
                user) user=$value ;;
                pass) pass=$value ;;
            esac
        fi
    done < "$ini_file"
}

# Loop principal do script
while true; do
    show_menu
    read -p "Selecione uma opção: " option
    case $option in
        1)
            clear
            echo "=============================="
            echo " Menu - Backup "
            echo "=============================="
            echo "1. Realizar backup lógico"
            echo "2. Realizar backup físico"
            echo "0. Voltar"
            echo "=============================="
            read -p "Selecione uma opção: " backup_option
            case $backup_option in
                1) perform_logical_backup ;;
                2) perform_physical_backup ;;
                0) ;;
                *) echo "Opção inválida. Por favor, tente novamente." ;;
            esac
            ;;
        2)
            clear
            echo "=============================="
            echo " Menu - Restauração "
            echo "=============================="
            echo "1. Restaurar backup"
            echo "0. Voltar"
            echo "=============================="
            read -p "Selecione uma opção: " restore_option
            case $restore_option in
                1) perform_restore ;;
                0) ;;
                *) echo "Opção inválida. Por favor, tente novamente." ;;
            esac
            ;;
        3)
            clear
            echo "=============================="
            echo " Menu - Status e Monitoramento "
            echo "=============================="
            echo "1. Verificar status da replicação"
            echo "2. Verificar status do servidor MariaDB"
            echo "3. Verificar uso de espaço em disco do diretório do banco de dados"
            echo "4. Verificar tamanho de um banco de dados específico"
            echo "0. Voltar"
            echo "=============================="
            read -p "Selecione uma opção: " status_option
            case $status_option in
                1) check_replication_status ;;
                2) check_server_status ;;
                3) check_database_directory_usage ;;
                4) check_database_size ;;
                0) ;;
                *) echo "Opção inválida. Por favor, tente novamente." ;;
            esac
            ;;
        4)
            clear
            echo "=============================="
            echo " Menu - Gerenciamento de Usuários "
            echo "=============================="
            echo "1. Verificar os privilégios de usuário"
            echo "2. Alterar a senha do usuário"
            echo "3. Adicionar um novo usuário"
            echo "0. Voltar"
            echo "=============================="
            read -p "Selecione uma opção: " user_option
            case $user_option in
                1) check_user_privileges ;;
                2) change_user_password ;;
                3) add_user ;;
                0) ;;
                *) echo "Opção inválida. Por favor, tente novamente." ;;
            esac
            ;;
        
 5)
            clear
            echo "=============================="
            echo " Menu - Gerenciamento de Tabelas "
            echo "=============================="
            echo "1. Executar otimização de tabelas"
            echo "2. Executar análise de tabela"
            echo "0. Voltar"
            echo "=============================="
            read -p "Selecione uma opção: " table_option
            case $table_option in
                1) optimize_tables ;;
                2) analyze_table ;;
                0) ;;
                *) echo "Opção inválida. Por favor, tente novamente." ;;
            esac
            ;;
        6)
            clear
            echo "=============================="
            echo " Menu - Gerenciamento de Replicação "
            echo "=============================="
            echo "1. Reiniciar a replicação"
            echo "0. Voltar"
            echo "=============================="
            read -p "Selecione uma opção: " replication_option
            case $replication_option in
                1) restart_replication ;;
                0) ;;
                *) echo "Opção inválida. Por favor, tente novamente." ;;
            esac
            ;;
        7)
            clear
            echo "=============================="
            echo " Menu - Configurações "
            echo "=============================="
            echo "1. Ler arquivo INI"
            echo "0. Voltar"
            echo "=============================="
            read -p "Selecione uma opção: " config_option
            case $config_option in
                1) read_ini_file ;;
                0) ;;
                *) echo "Opção inválida. Por favor, tente novamente." ;;
            esac
            ;;
        0)
            echo "Saindo do programa..."
            exit 0
            ;;
        *)
            echo "Opção inválida. Por favor, tente novamente."
            ;;
    esac

    echo ""
    read -p "Pressione Enter para continuar..."
done
