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

  -- get the cursor id and concatenate fetched row with separator or html table data tags
  FUNCTION CONCATENATE_ROW(i_CurNum    INTEGER,
                           v_separator VARCHAR2
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

      IF v_separator IS NULL THEN
        clob_Data := clob_Data || ' ' || HTF.TABLEDATA(clob_Temp, 'CENTER');
      ELSE
        clob_Data := clob_Data || nvl(clob_Temp,'undefined') || v_separator;
      END IF;
    END LOOP;

    RETURN(clob_Data);
  END;

  FUNCTION JS_PIE_FUNC(i_CurNum    INTEGER
                      ) RETURN CLOB IS
    i_ColCount      INTEGER;
    i_Count         INTEGER;
    clob_ColHeaders CLOB := null;
    clob_ColData    CLOB := null;
    clob_Data       CLOB := null;
    descTabRec      DBMS_SQL.DESC_TAB;
  BEGIN
    DBMS_SQL.DESCRIBE_COLUMNS(i_CurNum, i_ColCount, descTabRec);

    FOR i_Count IN descTabRec.first .. i_ColCount
    LOOP                       
      clob_ColHeaders := clob_ColHeaders || '"' || descTabRec(i_Count).col_name || '",';     
    END LOOP;

    LOOP
      i_Count := DBMS_SQL.FETCH_ROWS(i_CurNum);
      EXIT WHEN i_Count = 0;
      clob_Data := CONCATENATE_ROW(i_CurNum, ',');
    END LOOP;

    clob_Data := '
      <script type="text/javascript">
          function draw_pie() {  
              var canvas = document.getElementById("canvas");
              var ctx = canvas.getContext("2d");
              var canvas_size = [canvas.width, canvas.height];
              var data = [' || substr(clob_Data, 0, length(clob_Data)-1) || '], value = 0, total = 0;
              var labels = [' || substr(clob_ColHeaders, 0, length(clob_ColHeaders)-1) || '];
              var radius = Math.min(canvas_size[0], canvas_size[1]) / 2;
              var center = [canvas_size[0]/2, canvas_size[1]/2];
              var sofar = 0; // keep track of progress
              var i=0;
              var tempArray = [];
            
              for(var piece in data) {
                  if(data[piece]) {
                      total = total + data[piece];
                  }
                  else {
                      tempArray.push(piece);
                  }
              }

              for(var piece in tempArray.reverse()) {
                  data.splice(tempArray[piece], 1);
                  labels.splice(tempArray[piece], 1);
              }

              for (var piece in data) {
                  var thisvalue = data[piece] / total;

                  ctx.beginPath();
                  ctx.moveTo(center[0], center[1]); // center of the pie
                  ctx.arc(  // draw next arc
                        center[0],
                        center[1],
                        radius,
                        Math.PI * (- 0.5 + 2 * sofar), // -0.5 sets set the start to be top
                        Math.PI * (- 0.5 + 2 * (sofar + thisvalue)),
                        false
                    );

                  ctx.lineTo(center[0], center[1]); // line back to the center
                  ctx.closePath();
                  ctx.fillStyle = getColor();
                  ctx.fill();
                  ctx.strokeText(labels[i++],
                                 center[0] -30 + 0.75*radius * Math.cos(Math.PI * (- 0.5 + 2 * (sofar+0.5 * thisvalue))),
                                 center[1] + 0.75*radius * Math.sin(Math.PI * (- 0.5 + 2 * (sofar+0.5 * thisvalue))),
                                 50 
                                )
                  sofar += thisvalue;
               }
          }

          function getColor() {
              var rgb = [];
              for (var i = 0; i < 3; i++) {
                  rgb[i] = Math.round(100 * Math.random() + 155) ; // [155-255] = lighter colors
              }
              return "rgb(" + rgb.join(",") + ")";
          }
      </script>';

      RETURN clob_Data;
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
  
  FUNCTION CREATE_HTML(clob_Message   CLOB,
                       i_CurNum       INTEGER,
                       clob_HtmlStart CLOB,
                       clob_HtmlEnd   CLOB 
                      ) RETURN CLOB IS
    descTabRec  DBMS_SQL.DESC_TAB;
    i_ColCount  INTEGER;
    i_Count     INTEGER;
    clob_Html   CLOB;
    clob_Temp   CLOB;
   BEGIN
    DBMS_SQL.DESCRIBE_COLUMNS(i_CurNum, i_ColCount, descTabRec);

    clob_Html := clob_HtmlStart;

    -- set title of html
    clob_Html := clob_Html || HTF.TITLE(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS')) || CHR(10);
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
      clob_Temp := CONCATENATE_ROW(i_CurNum, NULL);
      clob_Html := clob_Html || clob_Temp || HTF.TABLEROWCLOSE || CHR(10);       
    END LOOP;
    -- close table
    clob_Html := clob_Html || HTF.TABLECLOSE;

    clob_Html := clob_Html || clob_HtmlEnd;

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
    clob_Data := CREATE_HTML(clob_Message, i_CurNum, '<html><body>', '</body></html>');

    RETURN clob_Data;
  END;

  FUNCTION ROW_TO_PIE_CHART_HTML(v_SqlStatement VARCHAR2,
                                 clob_Message   CLOB DEFAULT '') RETURN CLOB IS
    i_CurNum       INTEGER;
    curObj         refCur;
    clob_Data      CLOB := null;
    clob_JsData    CLOB := null;
  BEGIN
    OPEN curObj FOR v_SqlStatement;

    i_CurNum := DBMS_SQL.to_cursor_number(curObj);
    DEFINE_COLUMNS(i_CurNum);
    clob_JsData := JS_PIE_FUNC(i_CurNum);

    OPEN curObj FOR v_SqlStatement;

    i_CurNum := DBMS_SQL.to_cursor_number(curObj);
    DEFINE_COLUMNS(i_CurNum);

    clob_Data := CREATE_HTML(clob_Message, i_CurNum, '<html>' || clob_JsData || '<body onload="draw_pie()">', '<canvas id="canvas" width="300" height="300"></canvas></body></html>');

    RETURN clob_Data;
  END;

END PKG_TABLE_TO_HTML;
