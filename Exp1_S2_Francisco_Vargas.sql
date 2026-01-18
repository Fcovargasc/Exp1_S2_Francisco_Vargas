  -- TRUNCAR tabla destino para re-ejecuciones
  -- Permite ejecutar el bloque múltiples veces limpiando datos previos
TRUNCATE TABLE USUARIO_CLAVE;

DECLARE
  -- Variables %TYPE requeridas (mínimo 3)
  v_numrun_emp empleado.numrun_emp%TYPE;
  v_dvrun_emp empleado.dvrun_emp%TYPE;
  v_appaterno_emp empleado.appaterno_emp%TYPE;
  v_pnombre_emp empleado.pnombre_emp%TYPE;
  v_sueldo_base empleado.sueldo_base%TYPE;
  v_fecha_nac empleado.fecha_nac%TYPE;
  v_fecha_contrato empleado.fecha_contrato%TYPE;
  
  -- Variables de trabajo PL/SQL
  v_usuario VARCHAR2(20);
  v_clave VARCHAR2(20);
  v_nombre_empleado VARCHAR2(60);
  v_contador NUMBER := 0;
  v_anos_trabajo NUMBER;
  v_letras_apellido VARCHAR2(2);
  v_estado_civil_inicial CHAR(1);
  
BEGIN

 
  
  -- **Iteración sobre empleados existentes** (100-320)
  FOR rec IN (
    
    -- Une EMPLEADO con ESTADO_CIVIL para obtener nombre completo del estado civil
    SELECT e.id_emp, e.numrun_emp, e.dvrun_emp, e.appaterno_emp, e.pnombre_emp, 
           e.sueldo_base, e.fecha_nac, e.fecha_contrato, ec.nombre_estado_civil
    FROM empleado e, estado_civil ec 
    WHERE e.id_emp BETWEEN 100 AND 320 
    AND e.id_estado_civil = ec.id_estado_civil
    ORDER BY e.id_emp  -- Orden ascendente requerido
  ) LOOP
    
    -- Asignación variables %TYPE
    v_numrun_emp := rec.numrun_emp;
    v_dvrun_emp := rec.dvrun_emp;
    v_appaterno_emp := rec.appaterno_emp;
    v_pnombre_emp := rec.pnombre_emp;
    v_sueldo_base := rec.sueldo_base;
    v_fecha_nac := rec.fecha_nac;
    v_fecha_contrato := rec.fecha_contrato;
    
    -- Cálculo años trabajo (redondeo entero requerido)
    -- Usa MONTHS_BETWEEN para precisión y ROUND para entero sin decimales
    v_anos_trabajo := ROUND(MONTHS_BETWEEN(SYSDATE, v_fecha_contrato)/12);
    v_estado_civil_inicial := LOWER(SUBSTR(rec.nombre_estado_civil,1,1));
    v_nombre_empleado := v_pnombre_emp || ' ' || v_appaterno_emp;
    
    -- USUARIO - 
    v_usuario := v_estado_civil_inicial ||                    -- a) 1ra letra estado civil minúscula
                 LOWER(SUBSTR(v_pnombre_emp,1,3)) ||          -- b) 3 primeras letras nombre
                 LENGTH(v_pnombre_emp) ||                     -- c) largo nombre
                 '*' ||                                        -- d) asterisco
                 SUBSTR(TO_CHAR(v_sueldo_base),-1) ||         -- e) último dígito sueldo
                 v_dvrun_emp ||                               -- f) dígito verificador RUN
                 v_anos_trabajo ||                            -- g) años trabajando
                 CASE WHEN v_anos_trabajo < 10 THEN 'X' END;  -- h) X si menos de 10 años
    
    -- Letras apellido por estado civil ,Cada estado civil separado
    
    IF v_estado_civil_inicial = 'c' THEN              -- CASADO
      v_letras_apellido := LOWER(SUBSTR(v_appaterno_emp,1,2));
    ELSIF v_estado_civil_inicial = 'a' THEN           -- ACUERDO UNION CIVIL  
      v_letras_apellido := LOWER(SUBSTR(v_appaterno_emp,1,2));
    ELSIF v_estado_civil_inicial = 'd' THEN           -- DIVORCIADO
      v_letras_apellido := LOWER(SUBSTR(v_appaterno_emp,1,1)||SUBSTR(v_appaterno_emp,-1));
    ELSIF v_estado_civil_inicial = 's' THEN           -- SOLTERO
      v_letras_apellido := LOWER(SUBSTR(v_appaterno_emp,1,1)||SUBSTR(v_appaterno_emp,-1));
    ELSIF v_estado_civil_inicial = 'v' THEN           -- VIUDO
      v_letras_apellido := LOWER(SUBSTR(v_appaterno_emp,LENGTH(v_appaterno_emp)-2,2));
    ELSIF v_estado_civil_inicial = 'e' THEN           -- SEPARADO
      v_letras_apellido := LOWER(SUBSTR(v_appaterno_emp,-2));
    ELSE
      v_letras_apellido := LOWER(SUBSTR(v_appaterno_emp,1,2));
    END IF;
    
    
    -- CLAVE 
    v_clave := SUBSTR(TO_CHAR(v_numrun_emp),3,1) ||                    -- a) 3er dígito RUN
               (EXTRACT(YEAR FROM v_fecha_nac)+2) ||                   -- b) año nacimiento +2
               LPAD(TO_NUMBER(SUBSTR(TO_CHAR(v_sueldo_base),-3))-1,3,'0') || -- c) 3 últimos sueldo -1
               v_letras_apellido ||                                    -- d) 2 letras por estado civil
               rec.id_emp ||                                            -- e) ID empleado
               TO_CHAR(SYSDATE,'MMYY');                                -- f) mes/año actual (paramétrico)
    
    -- Inserta credenciales ordenadas por ID_EMP
    INSERT INTO USUARIO_CLAVE VALUES(rec.id_emp, v_numrun_emp, v_dvrun_emp, 
                                   v_nombre_empleado, v_usuario, v_clave);
    v_contador := v_contador + 1;
    
  END LOOP;
  
  -- COMMIT condicional (requerimiento técnico)
  IF v_contador > 0 THEN
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('? Exito: ' || v_contador || ' credenciales generadas');
  ELSE
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('? Error: No se procesaron empleados');
  END IF;
END;
/

-- 1. Activa mensajes (IMPORTANTE)
SET SERVEROUTPUT ON;

-- 2. VER TODOS los resultados como Figura 1
SELECT id_emp, 
       numrun_emp AS "RUN", 
       dvrun_emp AS "DVRUN",
       nombre_empleado, 
       nombre_usuario AS "NOMBRE _USUARIO", 
       clave_usuario AS "CLAVE_USUARIO"
FROM USUARIO_CLAVE 
ORDER BY id_emp;


