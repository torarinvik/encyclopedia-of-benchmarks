module binary_lifting_kth_ancestor
const max_nodes=256
const max_queries=1024
const levels=9
fn put(out &u8,slot int,value i64){bits:=u64(value);for i in 0..8{unsafe{out[slot*8+i]=u8(bits>>(i*8))}}}
@[export:'binary_lifting_kth_ancestor']
pub fn binary_lifting_kth_ancestor(input &i64,length usize,output &u8,capacity usize)i64{
 if isnil(input)||length<4{return -1};n64:=unsafe{input[0]};if n64<1||n64>max_nodes{return -1};n:=int(n64);root64:=unsafe{input[1]};m64:=unsafe{input[2]};q64:=unsafe{input[3]};if root64<0||root64>=n64||m64!=n64-1||q64<0||q64>max_queries{return -1};m:=int(m64);q:=int(q64);qo:=4+2*m;if length!=usize(qo+2*q){return -1};root:=int(root64)
 mut adj:=[max_nodes][max_nodes]bool{}
 for e in 0..m{a:=unsafe{input[4+2*e]};b:=unsafe{input[5+2*e]};if a<0||b<0||a>=n64||b>=n64||a==b{return -1};adj[int(a)][int(b)]=true;adj[int(b)][int(a)]=true}
 for i in 0..q{v:=unsafe{input[qo+2*i]};k:=unsafe{input[qo+2*i+1]};if v<0||v>=n64||k<0{return -1}}
 mut up:=[levels][max_nodes]int{};mut parent:=[max_nodes]int{};mut stack:=[max_nodes]int{};for i in 0..n{parent[i]= -1};parent[root]=root;up[0][root]=root;mut top:=0;mut reached:=0;stack[top]=root;top++
 for top>0{top--;u:=stack[top];reached++;for v in 0..n{if adj[u][v]{if v==parent[u]{continue};if parent[v]!= -1{return -1};parent[v]=u;up[0][v]=u;stack[top]=v;top++}}};if reached!=n{return -1}
 for level in 1..levels{for v in 0..n{up[level][v]=up[level-1][up[level-1][v]]}}
 bytes:=(1+q)*8;if isnil(output)||capacity<usize(bytes){return -2};put(output,0,i64(q))
 for i in 0..q{mut v:=int(unsafe{input[qo+2*i]});k:=u64(unsafe{input[qo+2*i+1]});if k>=u64(n){v=root}else{for bit in 0..levels{if (k&(u64(1)<<bit))!=0{v=up[bit][v]}}};put(output,1+i,i64(v))};return i64(bytes)
}
