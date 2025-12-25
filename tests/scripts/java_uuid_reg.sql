
CREATE FUNCTION ibm_uuid() RETURNING CHAR(36) EXTERNAL NAME 'com.informix.judrs.IfxStrings.getUUID()' language java;
GRANT EXECUTE ON ibm_uuid TO PUBLIC;

select ibm_uuid() from sysmaster:sysdual;
