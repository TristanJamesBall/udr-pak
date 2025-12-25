sqlq -d sysmaster <<-EOF

select 
first 5 *,
round(po_usedamt/1024/1024,1) po_used_MB
from syspools 
order by po_usedamt desc
EOF
