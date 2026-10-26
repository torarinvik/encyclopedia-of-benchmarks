// Clean-room bounded iterative-compression feedback vertex set profile.
package undirected_feedback_vertex_set
import "core:c"
MAX_N :: 8
MAX_INPUT :: 59
bit_count :: proc(x0:u64)->int{x:=x0;n:=0;for x!=0{n+=int(x&1);x>>=1};return n}
find_root :: proc(parent:^([MAX_N]int),value:int)->int{x:=value;for parent^[x]!=x{parent^[x]=parent^[parent^[x]];x=parent^[x]};return x}
is_forest :: proc(adj:[MAX_N][MAX_N]bool,n:int,vertices:u64)->bool{parent:[MAX_N]int;for i:=0;i<n;i+=1{parent[i]=i};for u:=0;u<n;u+=1{if vertices&(u64(1)<<u32(u))!=0{for v:=u+1;v<n;v+=1{if vertices&(u64(1)<<u32(v))!=0&&adj[u][v]{a:=find_root(&parent,u);b:=find_root(&parent,v);if a==b{return false};parent[a]=b}}}};return true}
compress :: proc(adj:[MAX_N][MAX_N]bool,n:int,prefix,current:u64,k:int,result:^u64)->bool{x:=current;for{cx:=bit_count(x);excluded:=current&~x;if cx<=k&&is_forest(adj,n,excluded){eligible:=prefix&~current;s:=eligible;for{if bit_count(s)<=k-cx&&is_forest(adj,n,prefix&~(x|s)){result^ = x|s;return true};if s==0{break};s=(s-1)&eligible}};if x==0{break};x=(x-1)&current};return false}
solve_budget :: proc(adj:[MAX_N][MAX_N]bool,n,k:int,answer:^u64)->bool{fvs:=u64(0);for i:=0;i<n;i+=1{prefix:=(u64(1)<<u32(i+1))-1;candidate:=fvs|(u64(1)<<u32(i));if bit_count(candidate)<=k{fvs=candidate;continue};next:=u64(0);if !compress(adj,n,prefix,candidate,k,&next){return false};fvs=next};answer^ = fvs;return true}
put :: proc(out:[^]u8,at:int,x:i64){b:=u64(x);for i:=0;i<8;i+=1{out[at+i]=u8(b&255);b>>=8}}
@(export)
undirected_feedback_vertex_set :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{if input==nil||length<3||length>MAX_INPUT do return -1;n64,m64,limit:=input[0],input[1],input[2];if n64<1||n64>8||m64<0||m64>28||limit<0||limit>4||length!=c.size_t(3+2*int(m64))do return -1;n,m:=int(n64),int(m64);adj:[MAX_N][MAX_N]bool;pu,pv:=i64(-1),i64(-1);for e:=0;e<m;e+=1{u,v:=input[3+2*e],input[4+2*e];if u<0||v<=u||v>=n64||u<pu||(u==pu&&v<=pv)do return -1;adj[int(u)][int(v)]=true;adj[int(v)][int(u)]=true;pu=u;pv=v};if output==nil||capacity<16 do return -2;found:=false;minimum:=i64(-1);answer:=u64(0);for budget:=0;budget<=int(limit);budget+=1{if solve_budget(adj,n,budget,&answer){found=true;minimum=i64(budget);break}};put(output,0,if found{1}else{0});put(output,8,minimum);return 16}
