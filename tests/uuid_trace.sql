{
execute procedure udr_trace_configure( 
	level=1, 
	class='udrpak',
	path='/var/tmp/udrpak.trace.log'
);
execute procedure udr_trace_set(100);

}
execute procedure udr_trace_on();
--execute procedure udr_trace_test();

execute function seq(2);

-- execute procedure udr_trace_set();
-- execute procedure udr_trace_test();
--execute procedure udr_trace_off();
execute function uuidv7();

execute function prng();