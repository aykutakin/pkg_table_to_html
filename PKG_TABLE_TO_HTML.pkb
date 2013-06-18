CREATE OR REPLACE PACKAGE BODY PKG_TABLE_TO_HTML AS

/*
* Created By    : Aykut Akin
* Creation Date : 10.01.2013
*/

---------------------Samples---------------------
/*
*------------------------------------------------
*  BEGIN
*   dbms_output.put_line(PKG_TABLE_TO_HTML.TABLE_TO_HTML('HR.EMPLOYEES','My header'));
*  END;
*------------------------------------------------
*  BEGIN
*   dbms_output.put_line(PKG_TABLE_TO_HTML.SQL_TO_HTML('SELECT EMPLOYEE_ID, FIRST_NAME || ' ' || LAST_NAME AS FULL_NAME FROM HR.EMPLOYEES','My header'));
*  END;
*------------------------------------------------
*/

  -- week cursor for fetching row
  TYPE refCur IS REF CURSOR;

  -- get the cursor id and concatenate fetched row as html row
  FUNCTION CONCATENATE_ROW(i_CurNum INTEGER
                          ) RETURN CLOB IS
    clob_Temp   CLOB;
    clob_Data   CLOB := null;
    i_Count     INTEGER;
    i_ColCount  INTEGER;
    descTabRec  DBMS_SQL.DESC_TAB;
    d_Temp      DATE;
    n_Temp      NUMBER;
  BEGIN
    -- to get columns type and columns count
    DBMS_SQL.DESCRIBE_COLUMNS(i_CurNum, i_ColCount, descTabRec);

    -- loop every column and concatenate
    FOR i_Count IN descTabRec.first .. i_ColCount
    LOOP
      IF descTabRec(i_Count).col_type = 1 THEN -- varchar2
        DBMS_SQL.COLUMN_VALUE(i_CurNum, i_Count, clob_Temp);
      ELSIF descTabRec(i_Count).col_type = 2 THEN -- number
        DBMS_SQL.COLUMN_VALUE(i_CurNum, i_Count, n_Temp);
        clob_Temp := TO_CHAR(n_Temp);
      ELSIF descTabRec(i_Count).col_type = 12 THEN -- date
        DBMS_SQL.COLUMN_VALUE(i_CurNum, i_Count, d_Temp);
        clob_Temp := TO_CHAR(d_Temp);  
      END IF;
      clob_Data := clob_Data || ' ' || HTF.TABLEDATA(clob_Temp, 'CENTER');
    END LOOP;

    RETURN(clob_Data);
  END;

  PROCEDURE DEFINE_COLUMNS(i_CurNum INTEGER
                          ) IS
    i_ColCount  INTEGER;
    descTabRec  DBMS_SQL.DESC_TAB;
    clob_Temp   CLOB;
    d_Temp      DATE;
    n_Temp      NUMBER;
  BEGIN
    -- to get columns type and columns count
    DBMS_SQL.DESCRIBE_COLUMNS(i_CurNum, i_ColCount, descTabRec);

    -- loop every column and define type
    FOR i_Count IN descTabRec.first .. i_ColCount
    LOOP
      IF descTabRec(i_Count).col_type = 1 THEN -- varchar2
        DBMS_SQL.DEFINE_COLUMN(i_CurNum, i_Count, clob_Temp);
      ELSIF descTabRec(i_Count).col_type = 2 THEN -- number
        DBMS_SQL.DEFINE_COLUMN(i_CurNum, i_Count, n_Temp);
      ELSIF descTabRec(i_Count).col_type = 12 THEN -- date
        DBMS_SQL.DEFINE_COLUMN(i_CurNum, i_Count, d_Temp);
      END IF;
    END LOOP;
  END;
  
  FUNCTION CREATE_HTML(clob_Message CLOB,
                       i_CurNum     INTEGER
                      ) RETURN CLOB IS
    descTabRec  DBMS_SQL.DESC_TAB;
    i_ColCount  INTEGER;
    i_Count     INTEGER;
    clob_Html   CLOB;
    clob_Temp   CLOB;
   BEGIN
    DBMS_SQL.DESCRIBE_COLUMNS(i_CurNum, i_ColCount, descTabRec);

    -- set title of html
    clob_Html := HTF.TITLE(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS')) || CHR(10);
    -- add custom message to header
    clob_Html := clob_Html || HTF.HEADER(3, TO_CHAR(clob_Message), 'CENTER') || CHR(10);
    -- open table
    clob_Html := clob_Html || HTF.TABLEOPEN('BORDER=1', 'CENTER', NULL, NULL, 'CELLPADDING=0') || CHR(10);
    
    -- new row for table header
    clob_Html := clob_Html || HTF.TABLEROWOPEN || CHR(10);
    -- loop all columns and set table headers
    FOR i_Count IN descTabRec.first .. i_ColCount
    LOOP                       
      clob_Html := clob_Html || HTF.TABLEDATA(HTF.STRONG(descTabRec(i_Count).col_name), 'CENTER') || CHR(10);     
    END LOOP;
    -- close row for table header
    clob_Html := clob_Html || HTF.TABLEROWCLOSE || CHR(10);

    -- fetch all rows in the table and prepare table
    LOOP
      i_Count := DBMS_SQL.FETCH_ROWS(i_CurNum);
      EXIT WHEN i_Count = 0;
      clob_Html := clob_Html || HTF.TABLEROWOPEN || CHR(10);
      clob_Temp := CONCATENATE_ROW(i_CurNum);
      clob_Html := clob_Html || clob_Temp || HTF.TABLEROWCLOSE || CHR(10);       
    END LOOP;
    -- close table
    clob_Html := clob_Html || HTF.TABLECLOSE;

    RETURN clob_Html; 
   END;
  
  FUNCTION TABLE_TO_HTML(v_TableName  VARCHAR2,
                         clob_Message CLOB DEFAULT '') RETURN CLOB IS
    clob_Data      CLOB := null;
  BEGIN
  
    clob_Data := SQL_TO_HTML('SELECT * FROM ' || v_TableName, clob_Message);

    RETURN clob_Data;
  END;
  
  FUNCTION SQL_TO_HTML(v_SqlStatement VARCHAR2,
                       clob_Message   CLOB DEFAULT '') RETURN CLOB IS
    i_CurNum       INTEGER;
    curObj         refCur;
    clob_Data      CLOB := null;
  BEGIN
    OPEN curObj FOR v_SqlStatement;

    i_CurNum := DBMS_SQL.to_cursor_number(curObj);
    DEFINE_COLUMNS(i_CurNum);
    clob_Data := CREATE_HTML(clob_Message, i_CurNum);

    RETURN clob_Data;
  END;

END PKG_TABLE_TO_HTML;
