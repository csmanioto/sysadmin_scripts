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
		$PGK install net-tools
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

	    if [ ! -f /tmp/install_mysql_dependences.ok ]; then
			echo "vm.swappiness = 0" > /etc/sysctl.d/mysql.conf
			echo "net.core.rmem_default = 33554432" >> /etc/sysctl.d/mysql.conf
			echo "net.core.wmem_default = 33554432" >> /etc/sysctl.d/mysql.conf
			echo "net.core.rmem_max = 33554432" >> /etc/sysctl.d/mysql.conf
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
		cd /usr/local/
		wget https://cdn.mysql.com//Downloads/MySQL-Shell/mysql-shell-8.0.21-linux-glibc2.12-x86-64bit.tar.gz
        tar -zxvf mysql-shell-8.0.21-linux-glibc2.12-x86-64bit.tar.gz
        ln -sf mysql-shell-8.0.21-linux-glibc2.12-x86-64bit mysql-shell


		echo "Select version. 5.7 or 8.0?"
		read VERSION
		if [ $VERSION = "8.0" ]; then 
			echo " Fazendo download do MYSQL 8.0"
			echo "8.0" > /tmp/mysql_instaled.log	
			wget https://cdn.mysql.com//Downloads/MySQL-8.0/mysql-test-8.0.21-linux-glibc2.17-x86_64-minimal.tar.xz
			tar -xvf mysql-test-8.0.21-linux-glibc2.17-x86_64-minimal.tar.xz
			ln -sf mysql-test-8.0.21-linux-glibc2.17-x86_64-minimal mysql
			mv mysql-test-8.0.21-linux-glibc2.17-x86_64-minimal.tar.xz /root/
			cd -
		else;
			echo " Fazendo download do MYSQL 5.7"	
			wget https://cdn.mysql.com//Downloads/MySQL-5.7/mysql-5.7.31-linux-glibc2.12-x86_64.tar.gz
 			tar -zxvf mysql-5.7.31-linux-glibc2.12-x86_64.tar.gz			
			ln -sf mysql-5.7.31-linux-glibc2.12-x86_64.tar.gz mysql
		fi;
		cd -

		echo "PATH=$PATH:/usr/local/mysql/bin" > /etc/profile.d/mysql.sh
        echo "PATH=$PATH:/usr/local/mysql-shell/bin" >> /etc/profile.d/mysql.sh
        echo "export MYSQLSH_PROMPT_THEME=/usr/local/mysql-shell/share/mysqlsh/prompt/prompt_256.json" >> /etc/profile.d/mysql.sh
		chmod 755 /etc/profile.d/mysql.sh
}


install_mysql_folders() {
	echo "Criando estrutura de pastas"
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
	echo "Vai usar LVM? (S/N) Se sim, vamos cancelar por hora para você continuar a configuração dos mount points"
	read LVM
	if [ $LVM = "S" ]; then
		echo "exemplos que podemos usar"
		echo "/dev/mapper/vg00-data /databases/mysql/bases xfs rw,discard,relatime,attr2,inode64,logbufs=8,logbsize=32k,sunit=32,swidth=192,noquota,noatime,nodiratime 0 0"
		echo "/dev/mapper/vg01-inno_log /databases/mysql/inno_log ext2 rw,noatime,nodiratime,relatime,stripe=8 0 0"
		echo "/dev/mapper/vg01-inno_undu /databases/mysql/inno_undu ext2 rw,noatime,nodiratime,relatime,stripe=8 0 0"
		echo "/dev/mapper/vg01-binlog /databases/mysql/binlog ext2 rw,noatime,nodiratime,relatime,stripe=8 0 0"
		echo "/dev/mapper/vg01-tmpdir /databases/mysql/tmpdir ext2 rw,noatime,nodiratime,relatime,stripe=8 0 0"
		echo "/dev/mapper/vg01-swap	none	swap sw"
		echo "/dev/sdb /databases/manobra ext4 rw,relatime 0 0"
		exit 
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




	MYSQL_INSTALED=$(cat /tmp/mysql_instaled.log)
	if [ $MYSQL_INSTALED = "5.7" ] then; 
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
	fi;

	if [ $MYSQL_INSTALED = "5.7" ] then; 
			echo "###########" 						> /databases/mysql/my.cnf
			echo "## By Carlos Smaniotto" 					>> /databases/mysql/my.cnf 
			echo "### my.cnf" 						>> /databases/mysql/my.cnf 
			echo "" 							>> /databases/mysql/my.cnf 
			echo ""								>> /databases/mysql/my.cnf 
			echo "[client]" 						>> /databases/mysql/my.cnf 
			echo "     port = 3306" 					>> /databases/mysql/my.cnf
			echo "    socket = /databases/mysql/mysql.socket" 		>> /databases/mysql/my.cnf
			echo "" 							>> /databases/mysql/my.cnf
			echo "     [mysqld_safe]" 					>> /databases/mysql/my.cnf
			echo "     timezone = America/Sao_Paulo" 			>> /databases/mysql/my.cnf
			echo "     socket = /databases/mysql/mysql.socket" 		>> /databases/mysql/my.cnf
			echo "     nice = 0" 						>> /databases/mysql/my.cnf
			echo "" 							>> /databases/mysql/my.cnf
			echo "     # LOGS e Slow Query" 				>> /databases/mysql/my.cnf
			echo "     log-error = /databases/mysql/logs/error.log"		>> /databases/mysql/my.cnf
			echo "     pid-file = /databases/mysql/bases/mysql.pid" 	>> /databases/mysql/my.cnf
			echo "" 							>> /databases/mysql/my.cnf
			echo "     [mysql]" 						>> /databases/mysql/my.cnf
			echo "	prompt=(\\u@\\h) [\\d]>\\_" 				>> /databases/mysql/my.cnf
			echo "" 							>> /databases/mysql/my.cnf
			echo "[mysqld]" 						>> /databases/mysql/my.cnf
			echo "# Geral" 							>> /databases/mysql/my.cnf
			echo "    port = 3306" 						>> /databases/mysql/my.cnf
			echo "    max_connections= 10000" 				>> /databases/mysql/my.cnf
			echo "    table_open_cache =  30000" 				>> /databases/mysql/my.cnf
			echo "    table_open_cache_instances =  32" 			>> /databases/mysql/my.cnf
			echo "    open_files_limit = 1048576" 				>> /databases/mysql/my.cnf
			echo "    max_allowed_packet =  1024M" 				>> /databases/mysql/my.cnf
			echo "    skip_name_resolve = 1" 				>> /databases/mysql/my.cnf
			echo "" 							>> /databases/mysql/my.cnf
			echo "    tmpdir = /databases/mysql/tmpdir" 			>> /databases/mysql/my.cnf
			echo "    lc-messages-dir = /usr/local/mysql/share/" 		>> /databases/mysql/my.cnf
			echo "    # LOG" 						>> /databases/mysql/my.cnf
			echo "    general_log_file = /databases/mysql/logs/general_log.log" >> /databases/mysql/my.cnf
			echo "    log-error = /databases/mysql/logs/error.log" 		>> /databases/mysql/my.cnf
			echo "    general_log = 1" 					>> /databases/mysql/my.cnf
			echo "    log_warnings = 1" 					>> /databases/mysql/my.cnf
			echo "" 							>> /databases/mysql/my.cnf
			echo "    pid-file = /databases/mysql/bases/mysqld.pid" 	>> /databases/mysql/my.cnf
			echo "    socket = /databases/mysql/mysqld.sock" 		>> /databases/mysql/my.cnf
			echo "    datadir = /databases/mysql/bases" 			>> /databases/mysql/my.cnf
			echo "    log-bin=/databases/mysql/binlog/mysql-bin" 		>> /databases/mysql/my.cnf
			echo "    relay-log = /databases/mysql/binlog/reley/relaylog" 	>> /databases/mysql/my.cnf
			echo "" 							>> /databases/mysql/my.cnf
			echo "    # Performance Analsys" 				>> /databases/mysql/my.cnf
			echo "    performance_schema = off" 				>> /databases/mysql/my.cnf
			echo "" 							>> /databases/mysql/my.cnf
			echo "# Replicacao" 						>> /databases/mysql/my.cnf
			echo "    #slave_parallel_workers =  8"				>> /databases/mysql/my.cnf
			echo "    #binlog_format =  ROW" 				>> /databases/mysql/my.cnf
			echo "    #binlog_row_image =  MINIMAL" 			>> /databases/mysql/my.cnf
			echo "    #log_bin_trust_function_creators =  on" 		>> /databases/mysql/my.cnf
			echo "    # Read only" 						>> /databases/mysql/my.cnf
			echo "        #super_read_only = OFF" 				>> /databases/mysql/my.cnf
			echo "        #read_only = OFF" 				>> /databases/mysql/my.cnf
			echo "# Logs" 							>> /databases/mysql/my.cnf
			echo "    # log_queries_not_using_indexes   =  on" 		>> /databases/mysql/my.cnf
			echo "    # long_query_time                 =  3" 		>> /databases/mysql/my.cnf
			echo "" 							>> /databases/mysql/my.cnf
			echo "" 							>> /databases/mysql/my.cnf
			echo "# InnoDB" 						>> /databases/mysql/my.cnf
			echo "    #innodb_dedicated_server = 1 	# When enabled, autotuning..." >> /databases/mysql/my.cnf
			echo "" 							>> /databases/mysql/my.cnf
			echo "    # Redo Log"  						>> /databases/mysql/my.cnf
			echo "    innodb_log_buffer_size = 4G" 				>> /databases/mysql/my.cnf
			echo "    innodb_log_group_home_dir = /databases/mysql/inno_log" >> /databases/mysql/my.cnf
			echo "    innodb_log_files_in_group = 10" 			>> /databases/mysql/my.cnf
			echo "    innodb_log_file_size = 1024M" 			>> /databases/mysql/my.cnf
			echo "" 							>> /databases/mysql/my.cnf
			echo "    # Undo" 						>> /databases/mysql/my.cnf
			echo "    innodb_data_home_dir = /databases/mysql/bases/" 	>> /databases/mysql/my.cnf
			echo "    innodb_undo_directory = /databases/mysql/inno_undu/" 	>> /databases/mysql/my.cnf
			echo "" 							>> /databases/mysql/my.cnf
			echo "    #Buffer Pool tunning" 				>> /databases/mysql/my.cnf
			echo "    innodb_buffer_pool_size =  ${BUFFER_POOL}G       # Buffer pool of 100GB for a 120GB server if the connection count is 500 or less, 84GB if max_connections is 10000" >> /databases/mysql/my.cnf
			echo "    innodb_buffer_pool_instances = 10      # This improves access to pool instances and makes each pool instance 6.25G" >> /databases/mysql/my.cnf
			echo "    innodb_change_buffer_max_size = 25     # This allows up to 50% of the buffer pool to be used for insert/change buffer" >> /databases/mysql/my.cnf
			echo "" 							>> /databases/mysql/my.cnf
			echo "    #Buffer Pool tunning Threads" 			>> /databases/mysql/my.cnf
			echo "    # innodb_log_writer_threads = ON        # 8.0.22 Enables dedicated log writer threads for writing redo log." >> /databases/mysql/my.cnf
			echo "    innodb_read_io_threads = 32             # Take advantage of more parallelism" >> /databases/mysql/my.cnf
			echo "    innodb_write_io_threads = 32            # Take advantage of more parallelism" >> /databases/mysql/my.cnf
			echo "    innodb_purge_threads = 8" 				>> /databases/mysql/my.cnf
			echo "    innodb_thread_concurrency =  64" 			>> /databases/mysql/my.cnf
			echo "    innodb_page_cleaners = 8" 				>> /databases/mysql/my.cnf
			echo "    innodb_purge_batch_size = 1600" 			>> /databases/mysql/my.cnf
			echo "    innodb_change_buffer_max_size = 30      # This allows up to 50% of the buffer pool to be used for insert/change buffer" >> /databases/mysql/my.cnf
			echo "    innodb_concurrency_tickets = 2500       # If you are writing many individual rows and not using multi-row inserts, AND this workload is INSERT heavy." >> /databases/mysql/my.cnf
			echo "                                            # For workloads that read a lot of rows, the default value of innodb_concurrency_tickets is appropriate." >> /databases/mysql/my.cnf
			echo "    #Buffer Pool tuning disk" 				>> /databases/mysql/my.cnf
			echo "    innodb_use_native_aio = 1" 				>> /databases/mysql/my.cnf
			echo "    innodb_flush_method=O_DIRECT_NO_FSYNC" 		>> /databases/mysql/my.cnf
			echo "" 							>> /databases/mysql/my.cnf
			echo "    innodb_flush_neighbors = 2              # Same GCP Config" >> /databases/mysql/my.cnf
			echo "    innodb_io_capacity = 2000               # Same GCP Config" >> /databases/mysql/my.cnf
			echo "    innodb_io_capacity_max = 5000" 			>> /databases/mysql/my.cnf
			echo "    innodb_lru_scan_depth = 2048            # Same GCP Config" >> /databases/mysql/my.cnf
			echo "    #innodb_purge_batch_size=300            # Same GCP Config" >> /databases/mysql/my.cnf
			echo "    innodb_file_per_table = 1               # It's split de innofile in one file per table. It helps to improve the performance" >> /databases/mysql/my.cnf
			echo "    # The following are non-ACID compliant adjustments that will improve performance, but use these settings can affect recoverability of data after a crash" >> /databases/mysql/my.cnf
			echo "        innodb_doublewrite = 1" 				>> /databases/mysql/my.cnf
			echo "        sync_binlog =  0" 				>> /databases/mysql/my.cnf
			echo "        innodb_flush_log_at_trx_commit =  2" 		>> /databases/mysql/my.cnf
	fi;
}
 
}

install_innotop() {
			cd /usr/local/src/
			git clone $INNOTOP
			cd innotop
			perl Makefile.PL
			make all install
}

pos_install() {
	adduser mysql
	source /etc/profile.d/mysql.sh
	cd /usr/local/mysql
	cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysql
	sed -i s'/basedir=/basedir=\/usr\/local\/mysql/g' /etc/init.d/mysql
	sed -i s'/datadir=/datadir=\/databases\/mysql\/bases\//g' /etc/init.d/mysql
	sed -i s'/conf=\/etc\/my.cnf/conf=\/databases\/mysql\/my.cnf/g' /etc/init.d/mysql
	sed -i s'/--datadir=\/databases\/mysql\/bases\/"$datadir"/--datadir="$datadir"/g' /etc/init.d/mysql

	chmod +x /etc/init.d/mysql
	chown mysql:mysql /databases/mysql/ -R
	mysqld --verbose --initialize
	rm -rf /databases/mysql/binlog/* 
	rm -rf /databases/mysql/innolog/*
	rm -rf  /databases/mysql/bases/* 
	rm -rf /databases/mysql/bases/logs*
	mysqld --defaults-file=/databases/mysql/my.cnf --initialize-insecure  --user=mysql --basedir=/usr/local/mysql --datadir=/databases/mysql/bases
}


core(){
			install_dependences;
			install_mysql_folders;
			install_mysql;
			install_my_cnf;
			pos_install;	
			install_innotop;	
	
			
}

clear
echo "Iniciando"
core;
