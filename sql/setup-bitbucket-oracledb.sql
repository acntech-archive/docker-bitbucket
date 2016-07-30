/*
* These sql statements are example of minimum setup for Oracle 12c Database for use with Bitbucket Server.
* This file is not being used by the docker image, but is rather an quickstart example of what is required
* according to https://confluence.atlassian.com/bitbucketserver/connecting-bitbucket-server-to-oracle-776640379.html
*
* $ su oracle
* $ $ORACLE_HOME/bin/sqlplus / as sysdba
* # copy paste sql statements below
*/

create tablespace bitbucket_tbs_01 datafile 'bitbucket_tbs_f2.dat' size 100m autoextend on online;
create user bitbucketdbuser identified by password default tablespace bitbucket_tbs_01 quota unlimited on bitbucket_tbs_01;
grant connect, resource to bitbucketdbuser;
grant create table to bitbucketdbuser;
create view bitbucketdbuser.all_objects as select * from sys.all_objects where owner = upper('bitbucketdbuser');