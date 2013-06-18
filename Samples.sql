------------------Samples---------------------

BEGIN
  dbms_output.put_line(PKG_TABLE_TO_HTML.TABLE_TO_HTML('HR.EMPLOYEES','My header'));
END;

----------------------------------------------

BEGIN
  dbms_output.put_line(PKG_TABLE_TO_HTML.SQL_TO_HTML('SELECT EMPLOYEE_ID, FIRST_NAME || '' '' || LAST_NAME AS FULL_NAME FROM HR.EMPLOYEES','My header'));
END;

----------------------------------------------
