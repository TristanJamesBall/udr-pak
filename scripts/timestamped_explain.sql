
drop procedure if exists set_explain_file;
drop procedure if exists set_explain;

create procedure set_explain(p_state varchar(16),p_path varchar(200) default 'sq_explain.', p_ext varchar(20) default '.txt' )

	define v_full varchar(250);
	define v_stmt1 lvarchar(100);
	define v_stmt2 lvarchar(500);
	define v_state varchar(16);

	let v_state =  
		decode( 
			lower(nvl(p_state,'on'))
			,'true'	,'on'
			,'t'	,'on'
			,'on'	,'on'
			,'y'	,'on'
			,'Yes'	,'on'
			,'on avoid_execute'		,'on avoid_execute'
			,'avoid_execute'		,'on avoid_execute'
			,'off'
		);
		

	let v_full  = p_path 
		|| to_char(current,'%Y-%m-%d__%H-%M-%S') 
		|| '.'
		|| dbinfo('sessionid')
		|| nvl(p_ext,'');

	let v_stmt1 = 'set explain ' || v_state;

	if v_state <> 'off' then
		let v_stmt2 = 'set explain file to '''||v_full||''';';
		execute immediate v_stmt2;
	end if;

	execute immediate v_stmt1;
end procedure;


execute procedure set_explain('on avoid_execute','myexplain.');
select * from sysmaster:sysdual;
execute function sysmaster:yieldn(2);
execute procedure set_explain('on','myexplain.');
select * from sysmaster:sysdual;
