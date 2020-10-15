#!/bin/bash

INNOTOP="https://github.com/innotop/innotop.git"
INNOTOP_PKG=$(echo $INNOTOP|cut -d'/' -f5)
INNOTOP_FOLDER=$(echo $INNOTOP_PKG|cut -d'.' -f1-3)
SERVER_ID=$(shuf -i 1-20 -n 1)

install_new_kernel(){
	echo "Install Kernel 5.8.13"
	cd /usr/local/
	wget https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.8.13/amd64/linux-modules-5.8.13-050813-generic_5.8.13-050813.202010011235_amd64.deb
	wget https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.8.13/amd64/linux-headers-5.8.13-050813-generic_5.8.13-050813.202010011235_amd64.deb
	wget https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.8.13/amd64/linux-headers-5.8.13-050813_5.8.13-050813.202010011235_all.deb
	wget https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.8.13/amd64/linux-image-unsigned-5.8.13-050813-generic_5.8.13-050813.202010011235_amd64.deb
	dpkg -i *.deb
	cd - 
}

install_dependences(){
        PGK="apt -y "
	echo "Instalando pre-requisitos e Atualizando do Linux"
        $PGK update
        $PGK upgrade
        $PGK install vim vim-scripts vim-syntastic vim-snippets vim-editorconfig
        $PGK install mycli
	$PGK install grc
        $PGK install zsh
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
        $PGK remove --purge -y percona-xtradb-cluster-server-5.7 percona-xtradb-cluster-garbd-5.7 percona-xtradb-cluster-common-5.7 percona-xtradb-cluster-client-5.7 percona-xtrabackup-24 percona-release
	$PGK remove --purge -y mysql-common mysql-server
	$PGK install libdbd-mysql-perl
	rm -rf /etc/mysql

	echo "installing man pages and others"
	unminimize


	if [ ! -f /tmp/install_mysql_dependences.ok ]; then
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
                echo " Fazendo download do MYSQL 8.0 "
                cd /usr/local/
		rm -f mysql*.tar.*
                wget https://cdn.mysql.com//Downloads/MySQL-8.0/mysql-8.0.21-linux-glibc2.17-x86_64-minimal.tar.xz
                tar -xvf mysql-8.0.21-linux-glibc2.17-x86_64-minimal.tar.xz
                ln -sf mysql-8.0.21-linux-glibc2.17-x86_64-minimal mysql

                wget https://cdn.mysql.com//Downloads/MySQL-Shell/mysql-shell-8.0.21-linux-glibc2.12-x86-64bit.tar.gz
                tar -zxvf mysql-shell-8.0.21-linux-glibc2.12-x86-64bit.tar.gz
                ln -sf mysql-shell-8.0.21-linux-glibc2.12-x86-64bit mysql-shell
                cd -

                echo "export PATH=$PATH:/usr/local/mysql/bin:/usr/local/mysql-shell/bin" > /etc/profile.d/mysql.sh
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
	# rm -f /databases/mysql/bases/*
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
	echo "    innodb_tmpdir = /databases/mysql/tmpdir" 		>> /databases/mysql/my.cnf
	echo "    lc-messages-dir = /usr/local/mysql/share/" 		>> /databases/mysql/my.cnf
	echo "    # LOG" 						>> /databases/mysql/my.cnf
	echo "    general_log_file = /databases/mysql/logs/general_log.log" >> /databases/mysql/my.cnf
	echo "    log-error = /databases/mysql/logs/error.log" 		>> /databases/mysql/my.cnf
	echo "    general_log = 1" 					>> /databases/mysql/my.cnf
	echo"	  log_error_verbosity = 2"				>> databases/mysql/my.cnf
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
	echo "    innodb_log_buffer_size = 120M" 			>> /databases/mysql/my.cnf
	echo "    innodb_log_group_home_dir = /databases/mysql/inno_log" >> /databases/mysql/my.cnf
	echo "    innodb_log_files_in_group = 1" 			>> /databases/mysql/my.cnf
	echo "    innodb_log_file_size = 1024M" 			>> /databases/mysql/my.cnf
	echo "" 							>> /databases/mysql/my.cnf
	echo "    # Undo" 						>> /databases/mysql/my.cnf
	echo "    innodb_data_home_dir = /databases/mysql/bases/" 	>> /databases/mysql/my.cnf
	echo "    innodb_undo_directory = /databases/mysql/inno_undu/" 	>> /databases/mysql/my.cnf
	echo "" 							>> /databases/mysql/my.cnf
	echo "    #Buffer Pool tunning" 				>> /databases/mysql/my.cnf
	echo "    innodb_buffer_pool_size =  ${BUFFER_POOL}G    # Buffer pool of 100GB for a 120GB server if the connection count is 500 or less, 84GB if max_connections is 10000" >> /databases/mysql/my.cnf
	echo "    innodb_buffer_pool_instances = 2      	# This improves access to pool instances and makes each pool instance 6.25G" >> /databases/mysql/my.cnf
	echo "    innodb_change_buffer_max_size = 25     	# This allows up to 50% of the buffer pool to be used for insert/change buffer" >> /databases/mysql/my.cnf
	echo "" 							>> /databases/mysql/my.cnf
	echo "    #Buffer Pool tunning Threads" 			>> /databases/mysql/my.cnf
	echo "    # innodb_log_writer_threads = ON        	# 8.0.22 Enables dedicated log writer threads for writing redo log." >> /databases/mysql/my.cnf
	echo "    innodb_read_io_threads = 32             	# Take advantage of more parallelism" >> /databases/mysql/my.cnf
	echo "    innodb_write_io_threads = 32            	# Take advantage of more parallelism" >> /databases/mysql/my.cnf
	echo "    innodb_purge_threads = 8" 				>> /databases/mysql/my.cnf
	echo "    innodb_thread_concurrency =  64" 			>> /databases/mysql/my.cnf
	echo "    innodb_page_cleaners = 8" 				>> /databases/mysql/my.cnf
	echo "    innodb_purge_batch_size = 1600" 			>> /databases/mysql/my.cnf
	echo "    innodb_change_buffer_max_size = 30      	# This allows up to 50% of the buffer pool to be used for insert/change buffer" >> /databases/mysql/my.cnf
	echo "    innodb_concurrency_tickets = 2500       	# If you are writing many individual rows and not using multi-row inserts, AND this workload is INSERT heavy." >> /databases/mysql/my.cnf
	echo "                                            	# For workloads that read a lot of rows, the default value of innodb_concurrency_tickets is appropriate." >> /databases/mysql/my.cnf
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
	echo "        innodb_doublewrite = 0" 				>> /databases/mysql/my.cnf
	echo "        sync_binlog =  0" 				>> /databases/mysql/my.cnf
	echo "        innodb_flush_log_at_trx_commit =  2" 		>> /databases/mysql/my.cnf
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
			install_dependences;
			install_mysql;
			install_mysql_folders;
			install_my_cnf;
			pos_install;
			install_innotop;


}

clear
echo "Iniciando"
core;
