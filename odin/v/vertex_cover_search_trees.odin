// Clean-room exact branch-and-search vertex-cover profile.
package vertex_cover_search_trees
import "core:c"
MAX_N :: 16
MAX_INPUT :: 131
bit_count :: proc(x0:u64)->int{ x:=x0;n:=0;for x!=0{n+=int(x&1);x>>=1};return n }
search :: proc(adj:[MAX_N][MAX_N]bool,n:int,active:u64)->u64{
 chosen:=n;best:=0;any:=false
 for u:=0;u<n;u+=1{if active&(u64(1)<<u32(u))!=0{degree:=0;for v:=0;v<n;v+=1{if active&(u64(1)<<u32(v))!=0&&adj[u][v]{degree+=1}};if degree>0{any=true;if chosen==n||degree>best{chosen=u;best=degree}}}}
 if !any{return 0};bit:=u64(1)<<u32(chosen);first:=bit|search(adj,n,active&~bit);neighbors:=u64(0);for v:=0;v<n;v+=1{if active&(u64(1)<<u32(v))!=0&&adj[chosen][v]{neighbors|=u64(1)<<u32(v)}};second:=neighbors|search(adj,n,active&~(neighbors|bit));a:=bit_count(first);b:=bit_count(second);if a<b{return first};if b<a{return second};return min(first,second)
}
put :: proc(out:[^]u8,at:int,x:i64){b:=u64(x);for i:=0;i<8;i+=1{out[at+i]=u8(b&255);b>>=8}}
@(export)
vertex_cover_search_trees :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<3||length>MAX_INPUT do return -1;n64,m64,k:=input[0],input[1],input[2];if n64<1||n64>16||m64<0||m64>64||k<0||k>n64||length!=c.size_t(3+2*int(m64))do return -1;n,m:=int(n64),int(m64)
 adj:[MAX_N][MAX_N]bool;pu,pv:=i64(-1),i64(-1);for e:=0;e<m;e+=1{u,v:=input[3+2*e],input[4+2*e];if u<0||v<=u||v>=n64||u<pu||(u==pu&&v<=pv)do return -1;adj[int(u)][int(v)]=true;adj[int(v)][int(u)]=true;pu=u;pv=v}
 if output==nil||capacity<24 do return -2;cover:=search(adj,n,(u64(1)<<u32(n))-1);count:=bit_count(cover);put(output,0,if i64(count)<=k{1}else{0});put(output,8,i64(count));put(output,16,i64(cover));return 24
}
