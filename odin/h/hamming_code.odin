package hamming_code
import "core:c"
@(export)
hamming_code :: proc "c" (a:[^]i64,n:c.size_t,out:[^]u8,cap:c.size_t)->i64{if a==nil||n<3 do return -1;r:=a[0];m:=a[1];if r<1||r>5||m<1||m>32||n!=c.size_t(2+m)||r+m<=((i64(1)<<u8(r))-(m-1))do return -1;for i:=i64(0);i<m;i+=1{if a[2+i]!=48&&a[2+i]!=49 do return -1};total:=int(r+m);if total<(1<<int(r-1))do return -1;if out==nil||cap<c.size_t(total+1)do return -2;code:[40]u8;data:=0;for p:=1;p<=total;p+=1{if p&(p-1)!=0||p>(1<<int(r-1)){code[p-1]=u8(a[2+data]);data+=1}else{code[p-1]=u8('0')}};for bit:=0;bit<int(r);bit+=1{parity:=1<<bit;value:=0;for p:=1;p<=total;p+=1{if p&parity!=0&&code[p-1]==u8('1'){value^=1}};code[parity-1]=u8('0'+value)};for i:=0;i<total;i+=1{out[i]=code[i]};out[total]=0;return i64(total)}
