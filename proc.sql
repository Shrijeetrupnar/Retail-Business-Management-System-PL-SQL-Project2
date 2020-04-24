create or replace package refcursor_jdbc1 as
type ref_cursor is ref cursor;
function getproducts
    return ref_cursor;
end;
/
show errors
create or replace package body refcursor_jdbc1 as
function getproducts
return ref_cursor as
rc ref_cursor;
begin
    open rc for
    select * from products;
    return rc;
end;
end;
/


create or replace package refcursor_jdbc1 as
type ref_cursor is ref cursor;
function getcustomers
    return ref_cursor;
end;
/
show errors
create or replace package body refcursor_jdbc1 as
function getcustomers
return ref_cursor as
rc ref_cursor;
begin
    open rc for
    select * from customers;
    return rc;
end;
end;
/

create or replace package refcursor_jdbc1 as
type ref_cursor is ref cursor;
function getpurchases
    return ref_cursor;
end;
/
show errors
create or replace package body refcursor_jdbc1 as
function getpurchases
return ref_cursor as
rc ref_cursor;
begin
    open rc for
    select * from purchases;
    return rc;
end;
end;
/


create or replace package refcursor_jdbc1 as
type ref_cursor is ref cursor;
function getemployees
    return ref_cursor;
end;
/
show errors
create or replace package body refcursor_jdbc1 as
function getemployees
return ref_cursor as
rc ref_cursor;
begin
    open rc for
    select * from employees;
    return rc;
end;
end;
/


create or replace package refcursor_jdbc1 as
type ref_cursor is ref cursor;
function getsuppliers
    return ref_cursor;
end;
/
show errors
create or replace package body refcursor_jdbc1 as
function getsuppliers
return ref_cursor as
rc ref_cursor;
begin
    open rc for
    select * from suppliers;
    return rc;
end;
end;
/


create or replace package refcursor_jdbc1 as
type ref_cursor is ref cursor;
function getsupply
    return ref_cursor;
end;
/
show errors
create or replace package body refcursor_jdbc1 as
function getsupply
return ref_cursor as
rc ref_cursor;
begin
    open rc for
    select * from supply;
    return rc;
end;
end;
/


create or replace package refcursor_jdbc1 as
type ref_cursor is ref cursor;
function getlogs
    return ref_cursor;
end;
/
show errors
create or replace package body refcursor_jdbc1 as
function getlogs
return ref_cursor as
rc ref_cursor;
begin
    open rc for
    select * from logs;
    return rc;
end;
end;
/
show errors;



CREATE OR REPLACE PROCEDURE report_monthly_sale(prod_id IN purchases.pid%type,Invaliderror OUT varchar2,c1 OUT sys_refcursor)
IS

Invalidpid exception;
count_values number;

BEGIN
select count(*) INTO count_values FROM purchases where pid = prod_id;
if(count_values = 0) THEN
	raise Invalidpid;
else
	OPEN c1 FOR
SELECT pur.pid,prod.pname,to_char(pur.ptime,'MON-YYYY')"Month",sum(pur.qty)"Quantity",sum(pur.total_price)"total_price",sum(pur.total_price)/sum(pur.qty)"Average" FROM purchases pur,products prod where pur.pid=prod.pid and pur.pid = prod_id group by pur.pid,prod.pname,to_char(pur.ptime, 'MON-YYYY');
end if;
exception
	when Invalidpid then
	Invaliderror:='Does not exist';
end report_monthly_sale;
/


create or replace procedure add_product(p_id in products.pid%type,
pname in products.pname%type,
qoh in products.qoh%type,
qoh_threshold in products.qoh_threshold%type,
original_price in products.original_price%type,
discnt_rate in products.discnt_rate%type,
error out varchar2) is

pid_error exception;
pid_count number;

BEGIN
select count(*) into pid_count from products where pid = p_id;
if(pid_count=0) then
raise pid_error;
else
insert into products (pid,pname,qoh,qoh_threshold,original_price,discnt_rate) values (p_id,pname,qoh,qoh_threshold,original_price, discnt_rate);
dbms_output.put_line('Added Successfully');

end if;

exception
when pid_error then
error:='Product does not exists';

END add_product;
/





create or replace procedure add_purchase(e_id in purchases.eid%type,
p_id in purchases.pid%type,
c_id in purchases.cid%type,
pur_qty in purchases.qty%type,
pur_output out varchar,
error out varchar2) is

pid_error exception;
eid_error exception;
cid_error exception;
pur_date date;
pur_total_price number(7,2);
next_pur# number(6);
og_price number(6,2);
pid_count number;
eid_count number;
cid_count number;

BEGIN
pur_date:=SYSDATE;
select count(*) into pid_count from products where pid = p_id;
select count(*) into eid_count from employees where eid = e_id;
select count(*) into cid_count from customers where cid = c_id;
SELECT prod.original_price into og_price from products prod where prod.pid = p_id;
pur_total_price := og_price * pur_qty;

if(eid_count=0) then
raise eid_error;

elsif(pid_count=0) then
raise pid_error;

elsif(cid_count=0) then
raise cid_error;

else


next_pur#:=pur_sequence.nextval;
insert into purchases values (next_pur#,e_id,p_id,c_id,
pur_qty, pur_date, pur_total_price);
dbms_output.put_line('Purchase Successful');

end if;

exception
when eid_error then
error:='Employee does not exists';

when pid_error then
error:='Product does not exists';

when cid_error then
error:='Customer does not exists';

END add_purchase;
/