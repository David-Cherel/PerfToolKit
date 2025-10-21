set verify off
set pagesize 999
set lines 165

create or replace function display_raw (rawval raw, type varchar2)
return varchar2
is
    cn     number;
    cv     varchar2(32);
    cd     date;
    cnv    nvarchar2(32);
    cr     rowid;
    cc     char(32);
    cbf    binary_float;
    cbd    binary_double;
begin
    if (type = 'VARCHAR2') then
        dbms_stats.convert_raw_value(rawval, cv);
        return to_char(cv);
    elsif (type = 'DATE') then
        dbms_stats.convert_raw_value(rawval, cd);
        return to_char(cd);
    elsif (type = 'NUMBER') then
        dbms_stats.convert_raw_value(rawval, cn);
        return to_char(cn);
    elsif (type = 'BINARY_FLOAT') then
        dbms_stats.convert_raw_value(rawval, cbf);
        return to_char(cbf);
    elsif (type = 'BINARY_DOUBLE') then
        dbms_stats.convert_raw_value(rawval, cbd);
        return to_char(cbd);
    elsif (type = 'NVARCHAR2') then
        dbms_stats.convert_raw_value(rawval, cnv);
        return to_char(cnv);
    elsif (type = 'ROWID') then
        dbms_stats.convert_raw_value(rawval, cr);
        return to_char(cr);
    elsif (type = 'CHAR') then
        dbms_stats.convert_raw_value(rawval, cc);
        return to_char(cc);
    else
        return 'UNKNOWN DATATYPE';
    end if;
end;
/

col table_name format a25 trunc
col column_name format a25
col avg_len format 9999999
col NDV format 999,999,999
col buckets format 999999
col low_value format a15
col high_value format a15
col density for .999999999
col data_type for a10
select column_name, data_type, avg_col_len, density, num_distinct NDV, histogram, num_buckets buckets, sample_size, last_analyzed, 
display_raw(low_value,data_type) low_value, display_raw(high_value,data_type) high_value
from dba_tab_cols 
where owner like nvl('&owner',owner)
and table_name like nvl('&table_name',table_name)
and column_name like nvl('%&column_name%',column_name)
order by internal_column_id
/
