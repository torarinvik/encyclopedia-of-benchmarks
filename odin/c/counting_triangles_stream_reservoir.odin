package counting_triangles_stream_reservoir

import "core:c"

put_i64 :: proc(out:[^]u8,offset:int,value:i64){bits:=cast(u64)value;for b:=0;b<8;b+=1{out[offset+b]=u8((bits>>u64(8*b))&255)}}

counting_triangles_stream_reservoir :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
	if input==nil||length<6||length>114 do return -1
	n0,m0:=input[0],input[1]
	if n0<2||n0>8||m0<1||m0>28||length!=c.size_t(2+4*m0) do return -1
	n,m:=int(n0),int(m0);seen:[8][8]bool;edges:[28][2]i64
	for i:=0;i<m;i+=1{u,v:=input[2+2*i],input[3+2*i];if u<0||v<=u||v>=n0||seen[int(u)][int(v)] do return -1;seen[int(u)][int(v)]=true;seen[int(v)][int(u)]=true;edges[i]=.{u,v}}
	base:=2+2*m
	for t:=1;t<=m;t+=1{for s:=0;s<2;s+=1{r:=input[base+2*(t-1)+s];if r<0||r>=i64(t) do return -1}}
	slots:[2][2]i64;slots[0]=.{-1,-1};slots[1]=.{-1,-1};staged:[112]i64;at:=0
	for t:=1;t<=m;t+=1{for s:=0;s<2;s+=1{if input[base+2*(t-1)+s]==0{slots[s]=edges[t-1]}};for s:=0;s<2;s+=1{staged[at]=slots[s][0];at+=1;staged[at]=slots[s][1];at+=1}}
	bytes:=16*m;if output==nil||capacity<c.size_t(bytes) do return -2
	for i:=0;i<at;i+=1{put_i64(output,8*i,staged[i])};return i64(bytes)
}
