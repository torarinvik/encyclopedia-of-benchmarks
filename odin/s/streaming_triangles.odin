package streaming_triangles

import "core:c"

power :: proc(base, exp: int) -> i64 { r:i64=1;for i:=0;i<exp;i+=1{r*=i64(base)};return r }
put_i64 :: proc(out:[^]u8,offset:int,value:i64){bits:=cast(u64)value;for b:=0;b<8;b+=1{out[offset+b]=u8((bits>>u64(8*b))&255)}}
make_wedge :: proc(a,b:[2]i64,out:^[2]i64)->bool{
	c:i64=-1;for i:=0;i<2;i+=1{for j:=0;j<2;j+=1{if a[i]==b[j] do c=a[i]}}
	if c<0 do return false
	x:=a[0];if x==c do x=a[1];y:=b[0];if y==c do y=b[1]
	if x==y do return false;if x>y do x,y=y,x
	out[0]=x;out[1]=y;return true
}

streaming_triangles :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
	if input==nil||length<10||length>340 do return -1
	n0,m0,se0,sw0:=input[0],input[1],input[2],input[3]
	if n0<2||n0>8||m0<1||m0>28||se0<2||se0>4||sw0<1||sw0>4 do return -1
	m,se,sw:=int(m0),int(se0),int(sw0);stride:=2+2*sw
	if length!=c.size_t(4+2*m+m*stride) do return -1
	edges:[28][2]i64;seen:[8][8]bool
	for i:=0;i<m;i+=1{u,v:=input[4+2*i],input[5+2*i];if u<0||v<=u||v>=n0||seen[int(u)][int(v)] do return -1;seen[int(u)][int(v)]=true;seen[int(v)][int(u)]=true;edges[i]=.{u,v}}
	edge_res:[4]int;for i:=0;i<4;i+=1{edge_res[i]=-1}
	wedge:[4][2]i64;wedge_valid:[4]bool;closed:[4]bool;total:i64=0;staged:[84]i64;at:=0;tape:=4+2*m
	for ti:=0;ti<m;ti+=1{t:=ti+1;rec:=tape+ti*stride
		for s:=0;s<sw;s+=1{if wedge_valid[s]&&wedge[s][0]==edges[ti][0]&&wedge[s][1]==edges[ti][1] do closed[s]=true}
		draw,slot0:=input[rec],input[rec+1];limit:=power(t,se);threshold:=limit-power(t-1,se);if draw<0||draw>=limit do return -1;update:=draw<threshold
		fresh:[4][2]i64;fresh_count:=0;removed_count:=0
		if update{if slot0<0||slot0>=i64(se) do return -1;slot:=int(slot0);old_id:=edge_res[slot];if old_id>=0{for j:=0;j<se;j+=1{if j!=slot&&edge_res[j]>=0{var old:[2]i64;if make_wedge(edges[old_id],edges[edge_res[j]],&old){removed_count+=1}}}};edge_res[slot]=ti;for j:=0;j<se;j+=1{if j!=slot&&edge_res[j]>=0{var out:[2]i64;if make_wedge(edges[ti],edges[edge_res[j]],&out){fresh[fresh_count]=out;fresh_count+=1}}}}else if slot0!=0 do return -1
		total+=i64(fresh_count-removed_count);if total<0 do return -1
		for s:=0;s<sw;s+=1{wd,pick:=input[rec+2+2*s],input[rec+3+2*s];if fresh_count>0{if wd<0||wd>=total do return -1;if wd<i64(fresh_count){if pick<0||pick>=i64(fresh_count) do return -1;wedge[s]=fresh[int(pick)];wedge_valid[s]=true;closed[s]=false}else if pick!=0 do return -1}else if wd!=0||pick!=0 do return -1}
		hits:=i64(0);for s:=0;s<sw;s+=1{if closed[s] do hits+=1};staged[at]=total;at+=1;staged[at]=(3*hits*1000000)/i64(sw);at+=1;staged[at]=(hits*i64(t)*i64(t)*total*1000000)/i64(sw*se*(se-1));at+=1
	}
	bytes:=24*m;if output==nil||capacity<c.size_t(bytes) do return -2;for i:=0;i<at;i+=1{put_i64(output,8*i,staged[i])};return i64(bytes)
}
