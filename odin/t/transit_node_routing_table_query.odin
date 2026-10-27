package transit_node_routing_table_query

import "core:c"

put_i64 :: proc(out:[^]u8,word:int,value:i64){bits:=cast(u64)value;for b:=0;b<8;b+=1{out[word*8+b]=u8((bits>>u64(8*b))&255)}}

transit_node_routing_table_query :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
	if input==nil||length<11||length>86 do return -1
	q0:=input[0];source:=input[1];target:=input[2];if q0<1||q0>8||source<0||source>=32||target<0||target>=32||input[3]!=1 do return -1
	q:=int(q0);at:=4;nf0:=input[at];at+=1;if nf0<1||nf0>4||nf0>q0||at+2*int(nf0)>int(length) do return -1
	nf:=int(nf0);f:[8]int;ds:[8]i64
	for i:=0;i<nf;i+=1{u:=input[at];d:=input[at+1];at+=2;if u<0||u>=q0||d<0||d>1000000 do return -1;for j:=0;j<i;j+=1{if f[j]==int(u)do return -1};f[i]=int(u);ds[i]=d}
	if at>=int(length) do return -1;nb0:=input[at];at+=1;if nb0<1||nb0>4||nb0>q0||at+2*int(nb0)>int(length) do return -1
	nb:=int(nb0);b:[8]int;dt:[8]i64
	for i:=0;i<nb;i+=1{v:=input[at];d:=input[at+1];at+=2;if v<0||v>=q0||d<0||d>1000000 do return -1;for j:=0;j<i;j+=1{if b[j]==int(v)do return -1};b[i]=int(v);dt[i]=d}
	if at+q*q!=int(length) do return -1;table:[8][8]i64
	for i:=0;i<q;i+=1{for j:=0;j<q;j+=1{d:=input[at];at+=1;if d<0||d>1000000 do return -1;table[i][j]=d}}
	for i:=0;i<q;i+=1{if table[i][i]!=0 do return -1}
	best:i64=1<<60;bestu:=0;bestv:=0
	for i:=0;i<nf;i+=1{for j:=0;j<nb;j+=1{d:=ds[i]+table[f[i]][b[j]]+dt[j];if d<best||(d==best&&(f[i]<bestu||(f[i]==bestu&&b[j]<bestv))){best=d;bestu=f[i];bestv=b[j]}}}
	if output==nil||capacity<24 do return -2;put_i64(output,0,best);put_i64(output,1,i64(bestu));put_i64(output,2,i64(bestv));return 24
}
