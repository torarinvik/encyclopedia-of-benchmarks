// Clean-room bounded iterative-compression feedback vertex set profile.
module undirected_feedback_vertex_set
const max_n=8
const max_input=59
const failure=u64(0xffffffffffffffff)
fn bit_count(mut x u64)int{mut n:=0;for x!=0{n+=int(x&1);x>>=1};return n}
fn find_root(mut parent [max_n]int,x0 int)int{mut x:=x0;for parent[x]!=x{parent[x]=parent[parent[x]];x=parent[x]};return x}
fn is_forest(adj [max_n][max_n]bool,n int,vertices u64)bool{mut parent:=[max_n]int{};for i in 0..n{parent[i]=i};for u in 0..n{if vertices&(u64(1)<<u32(u))!=0{for v in u+1..n{if vertices&(u64(1)<<u32(v))!=0&&adj[u][v]{a:=find_root(mut parent,u);b:=find_root(mut parent,v);if a==b{return false};parent[a]=b}}}};return true}
fn compress(adj [max_n][max_n]bool,n int,prefix u64,k int,current u64)u64{mut x:=current;for{cx:=bit_count(x);excluded:=current&~x;if cx<=k&&is_forest(adj,n,excluded){eligible:=prefix&~current;mut s:=eligible;for{if bit_count(s)<=k-cx&&is_forest(adj,n,prefix&~(x|s)){return x|s};if s==0{break};s=(s-1)&eligible}};if x==0{break};x=(x-1)&current};return failure}
fn solve_budget(adj [max_n][max_n]bool,n int,k int)u64{mut fvs:=u64(0);for i in 0..n{prefix:=(u64(1)<<u32(i+1))-1;candidate:=fvs|(u64(1)<<u32(i));if bit_count(candidate)<=k{fvs=candidate;continue};fvs=compress(adj,n,prefix,k,candidate);if fvs==failure{return failure}};return fvs}
fn minimum_fvs(adj [max_n][max_n]bool,n int,limit int)i64{for k in 0..limit+1{if solve_budget(adj,n,k)!=failure{return i64(k)}};return -1}
fn put_i64(mut out &u8,at int,value i64){bits:=u64(value);for i in 0..8{unsafe{out[at+i]=u8((bits>>(8*i))&255)}}}
@[export:'undirected_feedback_vertex_set']
pub fn undirected_feedback_vertex_set(input &i64,length usize,mut output &u8,capacity usize)i64{unsafe{if input==nil||length<3||length>max_input{return -1};n64,m64,limit:=input[0],input[1],input[2];if n64<1||n64>8||m64<0||m64>28||limit<0||limit>4||length!=usize(3+2*m64){return -1};n,m:=int(n64),int(m64);mut adj:=[max_n][max_n]bool{};mut pu,pv:=i64(-1),i64(-1);for e in 0..m{u,v:=input[3+2*e],input[4+2*e];if u<0||v<=u||v>=n64||u<pu||(u==pu&&v<=pv){return -1};adj[int(u)][int(v)]=true;adj[int(v)][int(u)]=true;pu=u;pv=v};if output==nil||capacity<16{return -2};minimum:=minimum_fvs(adj,n,int(limit));put_i64(mut output,0,if minimum<0{0}else{1});put_i64(mut output,8,minimum);return 16}}
