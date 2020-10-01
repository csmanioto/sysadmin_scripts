#!/bin/bash

rm -f /tmp/maestro_uuid.txt
rm -f /tmp/alter_table_uuid.sql

mysql -u root -e"select table_name, column_name, data_type, character_maximum_length from information_schema.columns where table_schema='maestro' and column_name like '%uuid%' INTO OUTFILE '/tmp/maestro_uuid.txt' FIELDS TERMINATED BY ' ' "

while read i; do
	tabela=$(echo $i | cut -d' ' -f1)
	coluna=$(echo $i | cut -d' ' -f2)
	tipo=$(echo $i | cut -d' ' -f3)
	size=$(echo $i | cut -d ' ' -f4)

	if [ "${tipo}" = 'varchar' ]; then
		novo_tipo="varbin"
	else
		novo_tipo="bin"
	fi;

	SQL="ALTER TALBE $tabela modify $coluna ${novo_tipo}($size);"
	echo $SQL >> /tmp/alter_table_uuid.sql
done < /tmp/maestro_uuid.txt

#mysql -u root maestro < /tmp/alter_table_uuid.sql
