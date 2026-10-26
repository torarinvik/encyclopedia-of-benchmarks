const TM_N = 9
const TM_Q = 24
const TM_R = 4
fn tm_put(mut out &u8, at int, x i64) { b:=u64(x); for i in 0..8 { unsafe { out[at+i]=u8((b>>(8*i))&255) } } }
fn tm_owned(g [][]bool, level []int, n int, u int) []int { mut a:=[]int{}; for v in 0..n { if g[u][v] && level[u]==0 && level[v]==0 { a<<v } }; return a }
fn tm_repair(g [][]bool, level []int, mut mate []int, n int, u int) { if u<0 || level[u]!=0 || mate[u]>=0 { return }; for v in 0..n { if g[u][v] && level[v]==0 && mate[v]<0 { mate[u]=v; mate[v]=u; return } } }
fn tm_promote(g [][]bool, mut level []int, mut mate []int, n int, u int, tape []int, r int, mut used int) bool { candidates:=tm_owned(g,level,n,u); if candidates.len==0 || used>=r || tape[used]>=candidates.len { return false }; y:=candidates[tape[used]]; used++; w:=mate[u]; x:=mate[y]; if w>=0 { mate[w]=-1; mate[u]=-1 }; if x>=0 { mate[x]=-1; mate[y]=-1 }; level[u]=1; level[y]=1; mate[u]=y; mate[y]=u; tm_repair(g,level,mut mate,n,w); if x!=w { tm_repair(g,level,mut mate,n,x) }; return true }
@[export: 'two_level_dynamic_maximal_matching_insertions']
pub fn two_level_dynamic_maximal_matching_insertions(input &i64,length usize,mut output &u8,capacity usize) i64 {
 unsafe {
  if input==nil || length<3 || length>55 { return -1 }; n64:=input[0]; q64:=input[1]; if (n64!=4 && n64!=9)||q64<0||q64>TM_Q||q64>n64*(n64-1)/2 { return -1 }; n:=int(n64); q:=int(q64); mut us:=[]int{len:q,init:0}; mut vs:=[]int{len:q,init:0}; mut seen:=[][]bool{len:TM_N,init:[]bool{len:TM_N,init:false}}; mut p:=2
  for e in 0..q { u64:=input[p];v64:=input[p+1];p+=2;if u64<0||v64<=u64||v64>=n64||seen[int(u64)][int(v64)] { return -1 };seen[int(u64)][int(v64)]=true;us[e]=int(u64);vs[e]=int(v64) }
  if p>=int(length) { return -1 };r64:=input[p];p++;if r64<0||r64>TM_R||int(length)!=p+int(r64) { return -1 };r:=int(r64);mut tape:=[]int{len:r,init:0};for i in 0..r{x:=input[p+i];if x<0||x>=n64{return -1};tape[i]=int(x)}
  mut g:=[][]bool{len:TM_N,init:[]bool{len:TM_N,init:false}};mut level:=[]int{len:TM_N,init:0};mut mate:=[]int{len:TM_N,init:-1};mut used:=0;t:=if n==4 { 2 } else { 3 }
  for e in 0..q { u:=us[e];v:=vs[e];g[u][v]=true;g[v][u]=true;if level[u]==1||level[v]==1{continue};if mate[u]<0&&mate[v]<0{mate[u]=v;mate[v]=u};du:=tm_owned(g,level,n,u).len;dv:=tm_owned(g,level,n,v).len;who:=if du>dv||(du==dv&&u<v){u}else{v};if tm_owned(g,level,n,who).len>=t&&!tm_promote(g,mut level,mut mate,n,who,tape,r,mut used){return -1} }
  if used!=r{return -1};bytes:=8*(1+2*n);if output==nil||capacity<usize(bytes){return -2};tm_put(mut output,0,i64(n));for i in 0..n{tm_put(mut output,8+8*i,i64(level[i]))};for i in 0..n{tm_put(mut output,8+8*n+8*i,i64(mate[i]))};return i64(bytes)
 }
}
