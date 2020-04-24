create sequence pur_sequence
   increment by 1
   start with 100001
   maxvalue 999999
   cycle
   order;
/

create sequence sup_sequence
        increment by 1
        start with 1
        maxvalue 100
        nocache
        cycle;
/

create sequence log_seq
        increment by 1
        start with 1
        maxvalue 100
        cycle
        order;
/



CREATE OR REPLACE TRIGGER LOG_TRIGGER_INSERT_PURCHASES
AFTER INSERT ON PURCHASES
FOR EACH ROW
BEGIN
INSERT INTO LOGS
(LOG#,WHO,OTIME,TABLE_NAME,OPERATION,KEY_VALUE)
VALUES(LOG_SEQ.NEXTVAL,user,sysdate,'PURCHASES','INSERT',:NEW.pur#);
END;
/


CREATE OR REPLACE TRIGGER LOG__TRIGGER_UPDATE_PRODUCTS
AFTER UPDATE OF QOH ON PRODUCTS
FOR EACH ROW
BEGIN
INSERT INTO LOGS
(LOG#,WHO,OTIME,TABLE_NAME,OPERATION,KEY_VALUE)
VALUES(LOG_SEQ.NEXTVAL,user,sysdate,'PRODUCTS','UPDATE',:NEW.pid);
END;
/

CREATE OR REPLACE TRIGGER LOG__TRIGGER_UPDATE_CUSTOMERS
AFTER UPDATE OF VISITS_MADE ON CUSTOMERS
FOR EACH ROW
BEGIN
INSERT INTO LOGS
(LOG#,WHO,OTIME,TABLE_NAME,OPERATION,KEY_VALUE)
VALUES(LOG_SEQ.NEXTVAL,user,sysdate,'CUSTOMERS','UPDATE',:NEW.cid);
END;
/


CREATE OR REPLACE TRIGGER LOG__TRIGGER_UPDATE_SUPPLY
AFTER INSERT ON SUPPLY
FOR EACH ROW
BEGIN
INSERT INTO LOGS
(LOG#,WHO,OTIME,TABLE_NAME,OPERATION,KEY_VALUE)
VALUES(LOG_SEQ.NEXTVAL,user,sysdate,'SUPPLY','INSERT',:NEW.sup#);
END;
/


create or replace trigger update_QOH_Check
Before insert on purchases
FOR EACH ROW
declare qoh_Insufficient exception;
        qoh_p number;
BEGIN
select qoh into qoh_p from products pr where pr.pid = :new.pid;
 if (:new.qty > qoh_p) then
        raise qoh_Insufficient;
 end if;
exception
when qoh_Insufficient then
      raise_application_error(-20003,'qoh_Insufficient');
end;
/


create or replace trigger UPDATE_QOHT
after insert on purchases
declare
pur#_id purchases.pur#%type;
p_id purchases.pid%type;
c_id purchases.cid%type;
pur_qty purchases.qty%type;
sup#_id supply.sup#%type;
sup_qty supply.quantity%type; 
temp_qoh_threshold products.qoh_threshold%type;
new_qoh products.qoh%type;
temp_visits_made customers.visits_made%type;
s_sid supply.sid%type;
sup_date date;
last_visit date;

BEGIN
Select sysdate into sup_date from dual;
select pur#,pid,cid,qty,ptime into pur#_id,p_id,c_id,pur_qty,last_visit from purchases group by pur#,pid,cid,qty,ptime having pur#=(select max(pur#) from purchases);
update products set qoh=qoh-pur_qty where pid=p_id;
select qoh, qoh_threshold into new_qoh, temp_qoh_threshold from products pr where pr.pid = p_id;
select visits_made INTO temp_visits_made from customers where cid=c_id;
update customers set visits_made = temp_visits_made+1 , last_visit_date = last_visit where cid=c_id;  	 	
if (new_qoh < temp_qoh_threshold) then
	dbms_output.put_line('Quantity on hand(qoh) is below the required threshold and new supply is required');
  sup_qty:=10+temp_qoh_threshold+1;
	select sid into s_sid from (select sid from supply where pid=p_id order by sid asc) where rownum = 1;
	insert into supply values (sup_sequence.nextval, p_id, s_sid, sup_date, sup_qty);
	update products set qoh=(qoh+sup_qty) where pid=p_id;
	dbms_output.put_line('New QOH: ' || (new_qoh+sup_qty));
end if;
end;
/

CREATE OR REPLACE TRIGGER PRODUCT_TRIGGER
AFTER DELETE ON PURCHASES
FOR EACH ROW
DECLARE
PROD_ID PURCHASES.PID%TYPE;
LAST_DATE PURCHASES.PTIME%TYPE;
BEGIN
UPDATE PRODUCTS SET PRODUCTS.QOH=PRODUCTS.QOH+:old.qty
WHERE PRODUCTS.PID=:old.pid;
UPDATE CUSTOMERS SET VISITS_MADE=VISITS_MADE+1,
LAST_VISIT_DATE=sysdate
WHERE CID=:old.cid;
END;
/


