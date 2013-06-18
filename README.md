pkg_table_to_html
=================

Allows you to create a html base table from database table.

This package is created using Oracle dynamic sql features. An sql query or table can be easily turned into html base table.

Execute
-------
Open command window and follow this sqlplus commands

    C:\Users\aakin>sqlplus /nolog
    
    SQL*Plus: Release 11.2.0.2.0 Production on Sal Haz 18 08:49:39 2013
    
    Copyright (c) 1982, 2010, Oracle.  All rights reserved.
    
    SQL> con {username}/{password}
    Connected.
    
    SQL> get PKG_TABLE_TO_HTML.pks NOLIST
     19
    SQL> /
    
    Package created.
    
    SQL> get PKG_TABLE_TO_HTML.pkb NOLIST
    152
    SQL> /
    
    Package body created.
