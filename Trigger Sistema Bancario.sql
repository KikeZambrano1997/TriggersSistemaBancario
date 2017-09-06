/*==============================================================*/
/*==============================================================*/
/*==============================================================*/

create or replace TRIGGER TR_B_IU_INSER_ACTIVOS_ACTUALES
BEFORE INSERT or UPDATE OF ACTIVOS_ACTUALES ON BANCO 
FOR EACH ROW 
declare
AC_AC exception;
BEGIN
IF :new.ACTIVOS_ACTUALES < 0 then
            RAISE AC_aC;
        END IF;
    exception
    when AC_AC then
    RAISE_APPLICATION_ERROR(-20002, 'LA BANCA NUNCA DEBER QUEDAR EN 0 ,: '||to_char(:new.ACTIVOS_ACTUALES));
END;

/*==============================================================*/
/*==============================================================*/
/*==============================================================*/

create or replace TRIGGER TR_A_IUD_PRESTAMOSS
BEFORE INSERT OR UPDATE OR DELETE ON PRESTAMO
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO AUDITORIA_PRESTAMO
        VALUES (:NEW.CEDULA_CLIENTE,SYSDATE,:NEW.FECHA_PRESTAMO,:NEW.MONTO_PRESTAMO,:NEW.INTERES_PRESTAMO,:NEW.NUMERO_CUOTAS,:NEW.SALDO_PRESTAMO,'INSERTO');
    END IF;
    IF UPDATING THEN
        INSERT INTO AUDITORIA_PRESTAMO
        VALUES (:OLD.CEDULA_CLIENTE,SYSDATE,:OLD.FECHA_PRESTAMO,:OLD.MONTO_PRESTAMO,:OLD.INTERES_PRESTAMO,:OLD.NUMERO_CUOTAS,:OLD.SALDO_PRESTAMO,'ACTUALIZO');
    END IF;
    IF DELETING THEN
        INSERT INTO AUDITORIA_PRESTAMO
        VALUES (:OLD.CEDULA_CLIENTE,SYSDATE,:OLD.FECHA_PRESTAMO,:OLD.MONTO_PRESTAMO,:OLD.INTERES_PRESTAMO,:OLD.NUMERO_CUOTAS,:OLD.SALDO_PRESTAMO,'EIMINO');
    END IF;
END;

/*==============================================================*/
/*==============================================================*/
/*==============================================================*/

create or replace TRIGGER TR_B_D_SALDO_PRESTAMO
BEFORE delete  ON  PRESTAMO 
FOR EACH ROW 
declare
ELI_SALDO exception;
BEGIN
IF :old.SALDO_PRESTAMO > 0 then
            RAISE ELI_SALDO;
        END IF;
    exception
    when ELI_SALDO then
    RAISE_APPLICATION_ERROR(-20002, 'NO SE PUEDE ELIMINAR EN ESTE CAMPO PORQUE UN TIENE UNA DEUDA ACTIVA,: '||to_char(:old.SALDO_PRESTAMO));

END;

/*==============================================================*/
/*==============================================================*/
/*==============================================================*/

create or replace TRIGGER TR_A_IU_FECHAPAGO_PAGO
AFTER INSERT OR UPDATE OF FECHA_PAGO ON PAGO
FOR EACH ROW
DECLARE

    FRECUENCIA FLOAT;
    FECHA DATE;
BEGIN
    SELECT FRECUENCIA_PAGO_DIAS INTO FRECUENCIA FROM PRESTAMO
    WHERE NUMERO_PRES=:NEW.NUMERO_PRES;
    FECHA := FRECUENCIA +  :NEW.FECHA_PAGO;
    update PRESTAMO set SIGUIENTE_PAGO = FECHA where NUMERO_PRES=:NEW.NUMERO_PRES;

END;

/*==============================================================*/
/*==============================================================*/
/*==============================================================*/

create or replace TRIGGER TR_B_IU_INSER_SALDO_PRESTAMO
BEFORE INSERT or UPDATE OF SALDO_PRESTAMO ON PRESTAMO 
FOR EACH ROW 
declare
NUE_SALDO exception;
BEGIN
IF :new.SALDO_PRESTAMO < 0 then
            RAISE NUE_SALDO;
        END IF;
    exception
    when NUE_SALDO then
    RAISE_APPLICATION_ERROR(-20002, 'SU PAGO ES MAYOR DE LO QUE DEBE,: '||to_char(:new.SALDO_PRESTAMO));
END;

/*==============================================================*/
/*==============================================================*/
/*==============================================================*/

create or replace TRIGGER tr_b_insetar_pago
after insert or update of VALOR_PAGO ON PAGO
DECLARE
CAPITAL number ;
VALOR number ;
nuevo_capital number ;
BEGIN
    select avg(PAGO.VALOR_PAGO),avg(BANCO.ACTIVOS_ACTUALES) into VALOR,capital from PAGO 
     JOIN PRESTAMO ON PAGO.NUMERO_PRES=PRESTAMO.NUMERO_PRES 
     JOIN CLIENTE ON PRESTAMO.CEDULA_CLIENTE=CLIENTE.CEDULA_CLIENTE
     JOIN BANCO ON CLIENTE.RUC=BANCO.RUC;

    nuevo_capital:= capital + VALOR;
    update BANCO set ACTIVOS_ACTUALES = nuevo_capital where RUC=RUC;  

END;

/*==============================================================*/
/*==============================================================*/
/*==============================================================*/

create or replace TRIGGER tr_b_iu_monto_prestamo

after INSERT or update of monto_prestamo ON PRESTAMO
DECLARE
nuevocapital number:=0 ;
capital number :=0;
VALOR_DEUDADO number :=0;
BEGIN

    select avg(PRESTAMO.MONTO_PRESTAMO),avg(BANCO.ACTIVOS_ACTUALES)
    into VALOR_DEUDADO,capital
    from PRESTAMO 
    JOIN CLIENTE ON PRESTAMO.CEDULA_CLIENTE=CLIENTE.CEDULA_CLIENTE 
    JOIN BANCO ON CLIENTE.RUC=BANCO.RUC ;

    nuevocapital:= capital - VALOR_DEUDADO;

    update BANCO set ACTIVOS_ACTUALES = nuevocapital where RUC=RUC; 
END;

/*==============================================================*/
/*==============================================================*/
/*==============================================================*/

create or replace TRIGGER tr_b_iu_tipo_cuenta
BEFORE INSERT OR UPDATE OF TIPO_CUENTA ON CUENTA 
FOR EACH ROW 
declare
NUE_TIPO exception;
BEGIN

     IF :NEW.TIPO_CUENTA <> 'ahorro' AND :NEW.TIPO_CUENTA <> 'corriente' then
            RAISE NUE_TIPO;
        END IF;

    IF :NEW.TIPO_CUENTA <> 'AHORRO' AND :NEW.TIPO_CUENTA <> 'CORRIENTE' then
            RAISE NUE_TIPO;
        END IF;
    exception
    when NUE_TIPO then
    RAISE_APPLICATION_ERROR(-20002, 'Solo permite cuenta de ahorro y corriente,: '||to_char(:new.TIPO_CUENTA));
END;

/*==============================================================*/
/*==============================================================*/
/*==============================================================*/

create or replace TRIGGER tr_b_iu_valor_pago
before
INSERT or update of valor_pago ON pago 
for each row
declare
nue_pago exception;
pago number;
deudavar number;
BEGIN
    select SALDO_PRESTAMO into deudavar from PRESTAMO where numero_pres = :new.numero_pres;
    DBMS_OUTPUT.PUT_LINE(deudavar); 
    pago := deudavar - :new.valor_pago;
    if pago < 0 then
        raise nue_pago;
     else 
		update PRESTAMO set SALDO_PRESTAMO = pago where numero_pres = :new.numero_pres;
    end if;
    exception
    when nue_pago then
    RAISE_APPLICATION_ERROR(-20002, 'El valor se excedio,: '
    ||to_char(pago));
END;

/*==============================================================*/
/*==============================================================*/
/*==============================================================*/