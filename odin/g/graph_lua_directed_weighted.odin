package graph_lua_directed_weighted
import "core:c"
put_i64 :: proc "contextless"(output:[^]u8,index:usize,value:i64){bits:=transmute(u64)value;for b:=0;b<8;b+=1{output[index*8+b]=u8(bits>>u64(8*b))}}
@(export)
graph_lua_directed_weighted :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<2 do return -1
 nv,ov:=input[0],input[1];if nv<1||nv>16||ov<0||ov>63||length!=usize(2+4*ov) do return -1;n,ops:=usize(nv),usize(ov)
 kind:[256]i64;weight:[256]i64;result_kind:[63]i64;result_value:[63]i64
 for i:usize=0;i<ops;i+=1{op,a,b,v:=input[2+4*i],input[3+4*i],input[4+4*i],input[5+4*i];if op<0||op>5||a<0||a>=nv||b<0||b>=nv do return -1;p:=usize(a*16+b);if op==0{if v< -1000||v>1000 do return -1;kind[p]=2;weight[p]=v;result_kind[i]=-1}else if op==1{if v!=0 do return -1;kind[p]=1;weight[p]=0;result_kind[i]=-1}else if op==2{if v!=0 do return -1;kind[p]=0;weight[p]=0;result_kind[i]=-1}else if op==3{if v!=0||kind[p]!=0 do return -1;kind[p]=1;weight[p]=0;result_kind[i]=-1}else if op==4{if v!=0 do return -1;result_kind[i]=kind[p];if kind[p]==2{result_value[i]=weight[p]}}else{if v!=0 do return -1;if kind[p]!=0{result_kind[i]=1}else{result_kind[i]=0}}}
 edges:usize=0;for a:usize=0;a<n;a+=1{for b:usize=0;b<n;b+=1{if kind[a*16+b]!=0{edges+=1}}};words:=2+2*ops+4*edges;if output==nil||capacity<words*8 do return -2;k:usize=0;put_i64(output,k,i64(ops));k+=1;for i:usize=0;i<ops;i+=1{put_i64(output,k,result_kind[i]);k+=1;put_i64(output,k,result_value[i]);k+=1};put_i64(output,k,i64(edges));k+=1;for a:usize=0;a<n;a+=1{for b:usize=0;b<n;b+=1{p:=a*16+b;if kind[p]!=0{put_i64(output,k,i64(a));k+=1;put_i64(output,k,i64(b));k+=1;put_i64(output,k,kind[p]);k+=1;put_i64(output,k,weight[p]);k+=1}}};return i64(words*8)
}
