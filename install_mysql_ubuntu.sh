#!/bin/bash

INNOTOP="https://github.com/innotop/innotop.git"
INNOTOP_PKG=$(echo $INNOTOP|cut -d'/' -f5)
INNOTOP_FOLDER=$(echo $INNOTOP_PKG|cut -d'.' -f1-3)
SERVER_ID=$(shuf -i 1-20 -n 1)

install_dependences(){
        PGK="apt -y "
	echo "Instalando pre-requisitos e Atualizando do Linux"
        $PGK update
        $PGK upgrade
        $PGK vim vim-scripts vim-syntastic vim-snippets vim-editorconfig
        $PGK mycli
	$PGK grc
        $PGK zsh
        $PGK install wget
	$PGK install sysstat
        $PGK install libncurses5
        $PGK install curl
        $PGK install iputils-ping
	$PGK install libaio1
	$PGK install irqbalance
	$PGK install libdbd-mysql-perl
	$PGK install libtime-hires-perl
	$PGK install libterm-readkey-perl
	$PGK install htop
	$PGK install atop
	$PGK install screen
        $PGK install xfsprogs
        $PGK install build-essential
        $PGK install checkinstall
        $PGK install libterm-readkey-perl
        $PGK install iftop
        $PGK install git
	$PGK install libdbd-mysql-perl
        $PGK remove --purge -y percona-xtradb-cluster-server-5.7 percona-xtradb-cluster-garbd-5.7 percona-xtradb-cluster-common-5.7 percona-xtradb-cluster-client-5.7 percona-xtrabackup-24 percona-release
		$PGK remove --purge -y mysql-common mysql-server
		rm -rf /etc/mysql

	echo "installing man pages and others"
	unminimize

        chsh -s $(which zsh)
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

	    if [ ! -f /tmp/install_mysql_dependences.ok ]; then
		#sed 's/enabled=0/enabled=1/g' -i /etc/yum.repos.d/CentOS-Base.repo
		#sed 's/enabled=0/enabled=1/g' -i /etc/yum.repos.d/redhat-rhui.repo
		#sed 's/SELINUX=enforcing/SELINUX=disabled/g ' -i /etc/selinux/config
		echo "vm.swappiness = 0" > /etc/sysctl.d/mysql.conf
		echo "net.core.rmem_default = 33554432" >> /etc/sysctl.d/mysql.conf
		echo "net.core.rmem_max = 33554432" >> /etc/sysctl.d/mysql.conf
		echo "net.core.wmem_default = 33554432" >> /etc/sysctl.d/mysql.conf
		echo "net.core.wmem_max = 33554432" >> /etc/sysctl.d/mysql.conf
		echo "net.ipv4.tcp_rmem = 10240 87380 33554432" >> /etc/sysctl.d/mysql.conf
		echo "net.ipv4.tcp_wmem = 10240 87380 33554432" >> /etc/sysctl.d/mysql.conf
		echo "net.core.netdev_max_backlog =25000" >> /etc/sysctl.d/mysql.conf
		echo "net.ipv4.tcp_max_tw_buckets = 1500000" >> /etc/sysctl.d/mysql.conf
		echo "net.ipv4.tcp_tw_reuse =  1" >> /etc/sysctl.d/mysql.conf
		echo "net.ipv4.ip_local_port_range = 15000 64000" >> /etc/sysctl.d/mysql.conf
		echo "net.core.somaxconn = 32000" >> /etc/sysctl.d/mysql.conf
		echo "fs.nr_open = 1248576" >> /etc/sysctl.d/mysql.conf
		sysctl -p /etc/sysctl.d/mysql.conf

    		echo "mysql   soft    nofile  1048576" >> /etc/security/limits.conf
    		echo "mysql   hard    nofile  1048576" >> /etc/security/limits.conf
          fi

}


install_mysql(){
                adduser mysql
                echo " Fazendo download do MYSQL 5.7 "
                cd /usr/local/
                wget https://cdn.mysql.com//Downloads/MySQL-8.0/mysql-8.0.21-linux-glibc2.17-x86_64-minimal.tar.xz
                wget https://cdn.mysql.com//Downloads/MySQL-8.0/mysql-test-8.0.21-linux-glibc2.17-x86_64-minimal.tar.xz
                #tar -xvf mysql-test-8.0.21-linux-glibc2.17-x86_64-minimal.tar.xz
                tar -xvf mysql-8.0.21-linux-glibc2.17-x86_64-minimal.tar.xz
                ln -sf mysql-8.0.21-linux-glibc2.17-x86_64-minimal mysql

                wget https://cdn.mysql.com//Downloads/MySQL-Shell/mysql-shell-8.0.21-linux-glibc2.12-x86-64bit.tar.gz
                tar -zxvf mysql-shell-8.0.21-linux-glibc2.12-x86-64bit.tar.gz
                ln -sf mysql-shell-8.0.21-linux-glibc2.12-x86-64bit mysql-shell
                cd -

                echo "PATH=$PATH:/usr/local/mysql/bin" > /etc/profile.d/mysql.sh
                echo "PATH=$PATH:/usr/local/mysql-shell/bin" >> /etc/profile.d/mysql.sh
                echo "export MYSQLSH_PROMPT_THEME=/usr/local/mysql-shell/share/mysqlsh/prompt/prompt_256.json" >> /etc/profile.d/mysql.sh
                chmod 755 /etc/profile.d/mysql.sh
}


install_mysql_folders() {
	mkdir -p  /databases/mysql/binlog/relay
	mkdir -p /databases/mysql/bases/
	mkdir -p /databases/mysql/logs
	mkdir -p  /databases/mysql/tmpdir/
	mkdir -p  /databases/mysql/inno_log
	mkdir -p  /databases/mysql/inno_undu
	rm -f /databases/mysql/bases/*
	if [ -f /etc/my.cnf ]; then
		mv /etc/my.cnf /etc/my.cnf_bkp_infrabanco
	fi
}

install_my_cnf (){
	if [ -f /databases/mysql/my.cnf ]; then
		mv /databases/mysql/my.cnf /etc/my.cnf_bkp_infrabanco
	fi

	echo "Quantos de RAM voce quer dedicar para o MySQL ? Sem nada = 90% "
	read BUFFER_POOL_PORCENT

	if [ -z $BUFFER_POOL_PORCENT ]; then
			BUFFER_POOL_PORCENT=90
	fi
	MEM_TOTAL=$(free -m|grep "Mem:"|awk '{ print $2}')
	BUFFER_POOL=$(expr ${MEM_TOTAL} \* $BUFFER_POOL_PORCENT / 100 / 1024)

	echo "###########" > /databases/mysql/my.cnfqcd /
	echo "## By Carlos Smaniotto" >> /databases/mysql/my.cnf
	echo "### my.cnf" >> /databases/mysql/my.cnf
	echo "" >> /databases/mysql/my.cnf

	echo "[client]" >> /databases/mysql/my.cnf
	echo "port            = 3307" >> /databases/mysql/my.cnf
	echo "socket          = /databases/mysql/mysql.sock" >> /databases/mysql/my.cnf
	echo "" >> /databases/mysql/my.cnf

	echo "[mysqld_safe]" >> /databases/mysql/my.cnf
	echo "basedir        = /usr/local/mysql" >> /databases/mysql/my.cnf
	echo "timezone        = America/Sao_Paulo" >> /databases/mysql/my.cnf
	echo "socket          = /databases/mysql/mysql.sock" >> /databases/mysql/my.cnf
	echo "nice            = 0" >> /databases/mysql/my.cnf
	echo "" >> /databases/mysql/my.cnf

	echo "# LOGS e Slow Query" >> /databases/mysql/my.cnf
	echo "log-error       = /databases/mysql/logs/error.log" >> /databases/mysql/my.cnf
	echo "pid-file        = /databases/mysql/bases/mysql.pid" >> /databases/mysql/my.cnf
	echo "" >> /databases/mysql/my.cnf

	echo "[mysqld]" >> /databases/mysql/my.cnf
	echo "general_log     = 1" >> /databases/mysql/my.cnf
	echo "log_warnings    = 1" >> /databases/mysql/my.cnf
	echo "general_log_file = /databases/mysql/logs/mysqld.log" >> /databases/mysql/my.cnf
	echo "log-error       = /databases/mysql/logs/error.log" >> /databases/mysql/my.cnf
	echo "log-slow-admin-statements = 0" >> /databases/mysql/my.cnf
	echo "" >> /databases/mysql/my.cnf

	echo "user            = mysql" >> /databases/mysql/my.cnf
	echo "pid-file        = /databases/mysql/bases/mysql.pid" >> /databases/mysql/my.cnf
	echo "socket          = /databases/mysql/mysql.socket" >> /databases/mysql/my.cnf
	echo "port            = 3307" >> /databases/mysql/my.cnf
	echo "basedir        = /usr/local/mysql" >> /databases/mysql/my.cnf
	echo "datadir         = /databases/mysql/bases/" >> /databases/mysql/my.cnf
	echo "tmpdir          = /databases/mysql/tmpdir" >> /databases/mysql/my.cnf
	echo "lc-messages-dir = /usr/local/mysql/share/" >> /databases/mysql/my.cnf
	echo "" >> /databases/mysql/my.cnf

	echo "# Performance Analsys" >> /databases/mysql/my.cnf
	echo "performance_schema = on" >> /databases/mysql/my.cnf
	echo "" >> /databases/mysql/my.cnf

	echo "# HARDELING" >> /databases/mysql/my.cnf
	echo "# Desativa o LOAD FILE" >> /databases/mysql/my.cnf
	echo "local-infile = 0" >> /databases/mysql/my.cnf
	echo "old_passwords=0" >> /databases/mysql/my.cnf
	echo "" >> /databases/mysql/my.cnf

	echo "# Enterprise plugin" >> /databases/mysql/my.cnf
	echo "#plugin-load=authentication_pam.so;thread_pool.so" >> /databases/mysql/my.cnf
	echo "" >> /databases/mysql/my.cnf

	echo "#thread_pool_size = 36" >> /databases/mysql/my.cnf
	echo "#thread_pool_stall_limit = 100" >> /databases/mysql/my.cnf
	echo "#thread_pool_prio_kickup_timer = 1000" >> /databases/mysql/my.cnf
	echo "#thread_pool_max_unused_threads = 0" >> /databases/mysql/my.cnf
	echo "" >> /databases/mysql/my.cnf

	echo "# HugTLB" >> /databases/mysql/my.cnf
	echo "#large-pages" >> /databases/mysql/my.cnf
	echo "" >> /databases/mysql/my.cnf

	echo "# 0x = MASTER" >> /databases/mysql/my.cnf
	echo "# 1x = Slave Level 1" >> /databases/mysql/my.cnf
	echo "# 2x = Slave em baixo de Slave" >> /databases/mysql/my.cnf
	echo "server-id=03" >> /databases/mysql/my.cnf

	echo "#Slave Setup" >> /databases/mysql/my.cnf
	echo "slave-skip-errors = 1062,1032,1452" >> /databases/mysql/my.cnf
	echo "relay-log = /databases/mysql/binlog/relay/mysql-relay-bin" >> /databases/mysql/my.cnf
	echo "read_only = 0" >> /databases/mysql/my.cnf
	echo "relay-log-space-limit=14G" >> /databases/mysql/my.cnf
	echo "relay-log-recovery" >> /databases/mysql/my.cnf

	echo "# Master Setup" >> /databases/mysql/my.cnf
	echo "binlog_format = ROW" >> /databases/mysql/my.cnf
	echo "log-bin        = /databases/mysql/binlog/mysql-bin" >> /databases/mysql/my.cnf
	echo "log_slave_updates = 1" >> /databases/mysql/my.cnf
	echo "log_bin_trust_function_creators = 1" >> /databases/mysql/my.cnf
	echo "expire_logs_days = 1" >> /databases/mysql/my.cnf

	echo "# Configuracoes Diversas" >> /databases/mysql/my.cnf
	echo "#Compatibilidade" >> /databases/mysql/my.cnf
	echo "sql_mode = ''" >> /databases/mysql/my.cnf

	echo "#skip-name-resolve" >> /databases/mysql/my.cnf
	echo "max_connections = 100" >> /databases/mysql/my.cnf
	echo "query_cache_size = 100M" >> /databases/mysql/my.cnf
	echo "query_cache_type = 1" >> /databases/mysql/my.cnf
	echo "sort_buffer_size = 1M" >> /databases/mysql/my.cnf
	echo "read_buffer_size = 64k" >> /databases/mysql/my.cnf
	echo "join_buffer_size = 1M" >> /databases/mysql/my.cnf
	echo "myisam_sort_buffer_size = 28M" >> /databases/mysql/my.cnf
	echo "bulk_insert_buffer_size = 64M" >> /databases/mysql/my.cnf
	echo "max_allowed_packet = 1024M" >> /databases/mysql/my.cnf
	echo "open-files-limit= 1048576" >> /databases/mysql/my.cnf
	echo "thread_cache_size = 100" >> /databases/mysql/my.cnf
	echo "" >> /databases/mysql/my.cnf

	echo "# Temporary Table" >> /databases/mysql/my.cnf
	echo "        # Configura o tamanho maximo para tabela do tipo MEMORY" >> /databases/mysql/my.cnf
	echo "        max_heap_table_size = 512M" >> /databases/mysql/my.cnf
	echo "        # Configura o tamanho maximo antes de converter para MyISAM" >> /databases/mysql/my.cnf
	echo "        tmp_table_size = 1G" >> /databases/mysql/my.cnf
	echo "" >> /databases/mysql/my.cnf

	echo "# Federated Store Engine" >> /databases/mysql/my.cnf
	echo "federated" >> /databases/mysql/my.cnf
	echo "" >> /databases/mysql/my.cnf

	echo "# MyISAM Store Engine" >> /databases/mysql/my.cnf
	echo "key_buffer = 128M" >> /databases/mysql/my.cnf
	echo "myisam_repair_threads = 1" >> /databases/mysql/my.cnf
	echo "myisam_recover = FORCE" >> /databases/mysql/my.cnf
	echo "" >> /databases/mysql/my.cnf

	echo "# InnoDB (Default)" >> /databases/mysql/my.cnf
	echo "" >> /databases/mysql/my.cnf
	echo "        # Depreciado na 5.6 - Armazena dicionario de dados na ram" >> /databases/mysql/my.cnf
	echo "        # innodb_additional_mem_pool_size = 16M" >> /databases/mysql/my.cnf
	echo "" >> /databases/mysql/my.cnf

	echo "        # BUFFER POOL" >> /databases/mysql/my.cnf
	echo "        # Faz  pre-load do buffer pool no startup" >> /databases/mysql/my.cnf
	echo "        innodb_buffer_pool_load_at_startup=OFF" >> /databases/mysql/my.cnf
	echo "        innodb_buffer_pool_size = ${BUFFER_POOL}G" >> /databases/mysql/my.cnf
	echo "        # Segregacao do buffer_pool - Performance para algoritmo LRU (qtd cpu)" >> /databases/mysql/my.cnf
	echo "        innodb_buffer_pool_instance = 3" >> /databases/mysql/my.cnf
	echo "" >> /databases/mysql/my.cnf

	echo "        # Porcentagem de Paginas Sujas permitida" >> /databases/mysql/my.cnf
	echo "        # Configuravel em realtime" >> /databases/mysql/my.cnf
	echo "        # Faz flush das paginas vizinhas junto, economizando I/O" >> /databases/mysql/my.cnf
	echo "        innodb_flush_neighbors" >> /databases/mysql/my.cnf
	echo "        # Define o que o flush das dirty pages seja ajustada conforme o workload" >> /databases/mysql/my.cnf
	echo "        innodb_adaptive_flushing" >> /databases/mysql/my.cnf
	echo "" >> /databases/mysql/my.cnf

	echo "        # Redo Log" >> /databases/mysql/my.cnf
	echo "        innodb_log_buffer_size = 1G" >> /databases/mysql/my.cnf
	echo "        innodb_log_group_home_dir = /databases/mysql/innolog" >> /databases/mysql/my.cnf
	echo "        innodb_log_files_in_group = 2" >> /databases/mysql/my.cnf
	echo "        innodb_log_file_size = 2024M" >> /databases/mysql/my.cnf
	echo "" >> /databases/mysql/my.cnf

	echo "        # Manipulacao de arquivos" >> /databases/mysql/my.cnf
	echo "        innodb_open_files = 1048576" >> /databases/mysql/my.cnf
	echo "        innodb_file_per_table = 1" >> /databases/mysql/my.cnf
	echo "        innodb_data_file_path = ibdata1:1G:autoextend" >> /databases/mysql/my.cnf
	echo "        innodb_data_home_dir=/databases/mysql/bases/" >> /databases/mysql/my.cnf
	echo "" >> /databases/mysql/my.cnf
	echo "        # O_DIRECT para fazer by-pass (O EBS controla)" >> /databases/mysql/my.cnf
	echo "        innodb_flush_method = O_DIRECT" >> /databases/mysql/my.cnf
	echo "        innodb_file_format = BARRACUDA" >> /databases/mysql/my.cnf
	echo "        # QTD de IOPS que esta disponível para o datadir" >> /databases/mysql/my.cnf
	echo "        innodb_io_capacity = 1000" >> /databases/mysql/my.cnf
	echo "" >> /databases/mysql/my.cnf
	echo "        # Controle Transacional" >> /databases/mysql/my.cnf
	echo "        transaction-isolation=READ-COMMITTED" >> /databases/mysql/my.cnf
	echo "        innodb_support_xa = 0" >> /databases/mysql/my.cnf
	echo "        # Qtd de segundos antes de um Lock wait timeout exceeded" >> /databases/mysql/my.cnf
	echo "        innodb_lock_wait_timeout = 120" >> /databases/mysql/my.cnf
}

install_innotop() {
			cd /root/
			git clone $INNOTOP
			cd innotop
			perl Makefile.PL
			make all install
}

pos_install() {
	useradd mysql
	source /etc/profile.d/mysql.sh
	cd /usr/local/mysql
	cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysql
	sed -i s'/basedir=/basedir=\/usr\/local\/mysql/g' /etc/init.d/mysql
	sed -i s'/datadir=/datadir=\/databases\/mysql\/bases\//g' /etc/init.d/mysql
	sed -i s'/conf=\/etc\/my.cnf/conf=\/databases\/mysql\/my.cnf/g' /etc/init.d/mysql
	sed -i s'/--datadir=\/databases\/mysql\/bases\/"$datadir"/--datadir="$datadir"/g' /etc/init.d/mysql
	ln -sf /databases/mysql/my.cnf /etc/my.cnf
	systemctl enable mysql.service

	chmod +x /etc/init.d/mysql
	chown mysql:mysql /databases/mysql/ -R
	#mysqld --verbose --initialize
	rm -rf /databases/mysql/binlog/*
	rm -rf /databases/mysql/inno_log/*
	rm -rf /databases/mysql/inno_undu/*
	rm -rf  /databases/mysql/bases/*
	rm -rf /databases/mysql/logs/*
	rm -rf /databases/mysql/tmpdir/*
	mysqld --verbose --initialize-insecure  --user=mysql --basedir=/usr/local/mysql --datadir=/databases/mysql/bases
}


pos_install_perfum() {
	cd ~
	echo "if has("autocmd")" >> .vimrc
        echo "   autocmd BufRead *.sql set filetype=mysql" >> .vimrc
        echo "   autocmd BufRead *.test set filetype=mysql" >> .vimrc
	echo "endif" >> .vimrc
	echo " " >> .vimrc
	echo "autocmd BufNewFile,BufRead *.conf,*.cnf set syntax=dosini" >> .vimrc
}


core(){
			#install_dependences;
			#install_mysql;
			#install_mysql_folders;
			#install_my_cnf;
			pos_install;
			#install_innotop;


}

clear
echo "Iniciando"
core;
