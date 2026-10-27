package two_edge_connected_spanning_subgraph_greedy
import "core:c"
MAX_N :: 8
MAX_M :: 28
MAX_INPUT :: 59
put :: proc(o:[^]u8,at:int,x:i64){b:=u64(x);for i:=0;i<8;i+=1{o[at+i]=u8(b&255);b>>=8}}
connected :: proc(n,m:int,u,v:[^]int,on:[^]bool,skip:int)->bool{seen:[MAX_N]bool;queue:[MAX_N]int;head,tail:=0,1;queue[0]=0;seen[0]=true;for head<tail{a:=queue[head];head+=1;for e:=0;e<m;e+=1{if !on[e]||e==skip do continue;b:=MAX_N;if u[e]==a{b=v[e]}else if v[e]==a{b=u[e]};if b<MAX_N&&!seen[b]{seen[b]=true;queue[tail]=b;tail+=1}}};for i:=0;i<n;i+=1{if !seen[i] do return false};return true}
edge_connected :: proc(n,m:int,u,v:[^]int,on:[^]bool)->bool{if !connected(n,m,u,v,on,-1) do return false;for e:=0;e<m;e+=1{if on[e]&&!connected(n,m,u,v,on,e) do return false};return true}
@(export)
two_edge_connected_spanning_subgraph_greedy :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<2||length>MAX_INPUT do return -1;n0,m0:=input[0],input[1];if n0<3||n0>8||m0<3||m0>28||length!=c.size_t(2+2*m0) do return -1;n,m:=int(n0),int(m0)
 u:[MAX_M]int;v:[MAX_M]int;on:[MAX_M]bool
 for i:=0;i<m;i+=1{a,b:=input[2+2*i],input[3+2*i];if a<0||a>=b||b>=n0 do return -1;u[i]=int(a);v[i]=int(b);on[i]=true;for j:=0;j<i;j+=1{if u[i]==u[j]&&v[i]==v[j] do return -1}}
 if !edge_connected(n,m,&u[0],&v[0],&on[0]) do return -1
 for e:=0;e<m;e+=1{on[e]=false;if !edge_connected(n,m,&u[0],&v[0],&on[0]){on[e]=true}}
 count:=0;for e:=0;e<m;e+=1{if on[e]{count+=1}};bytes:=8*(1+2*count);if output==nil||capacity<c.size_t(bytes) do return -2;put(output,0,i64(count));at:=8
 for a:=0;a<n;a+=1{for b:=a+1;b<n;b+=1{for e:=0;e<m;e+=1{if on[e]&&u[e]==a&&v[e]==b{put(output,at,i64(a));put(output,at+8,i64(b));at+=16}}}}
 return i64(bytes)
}
