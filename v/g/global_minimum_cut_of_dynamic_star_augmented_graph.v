module global_minimum_cut_of_dynamic_star_augmented_graph
const max_n=16
const max_m=64
const max_q=32
const max_v=17
const max_input=276
const max_output=256
const max_w=i64(1000000)
fn store_le(mut out &u8,at int,x i64){mut bits:=u64(x);for b in 0..8{unsafe{out[at+b]=u8(bits&255)};bits>>=8}}
fn stoer_wagner(n int,spokes []i64,eu []i64,ev []i64,ew []i64,m int)i64{
 vc:=n+1;mut w:=[max_v][max_v]i64{};for e in 0..m{u:=int(eu[e]);v:=int(ev[e]);w[u][v]+=ew[e];w[v][u]+=ew[e]};for u in 0..n{w[u][n]+=spokes[u];w[n][u]+=spokes[u]}
 mut active:=[max_v]int{};mut count:=vc;for i in 0..vc{active[i]=i};mut best:=i64(0x7fffffffffffffff)
 for count>1{mut used:=[max_v]bool{};mut connection:=[max_v]i64{};mut previous:=-1
  for step in 0..count{mut selected:=-1;for z in 0..count{u:=active[z];if !used[u]&&(selected<0||connection[u]>connection[selected]||(connection[u]==connection[selected]&&u<selected)){selected=u}}
   if step+1==count{if connection[selected]<best{best=connection[selected]};for z in 0..count{u:=active[z];if u!=selected&&u!=previous{w[previous][u]+=w[selected][u];w[u][previous]=w[previous][u]}};mut pos:=0;for active[pos]!=selected{pos++};for z in pos+1..count{active[z-1]=active[z]};count--;break}
   used[selected]=true;previous=selected;for z in 0..count{u:=active[z];if !used[u]{connection[u]+=w[selected][u]}}
  }
 };return best
}
@[export:'global_minimum_cut_of_dynamic_star_augmented_graph']
pub fn global_minimum_cut_of_dynamic_star_augmented_graph(input &i64,length usize,mut output &u8,capacity usize)i64{
 unsafe{
  if input==nil||length<3||length>max_input{return -1};n0:=input[0];m0:=input[1];q0:=input[2];if n0<1||n0>max_n||m0<0||m0>max_m||m0>n0*(n0-1)/2||q0<1||q0>max_q{return -1}
  n:=int(n0);m:=int(m0);q:=int(q0);if length!=usize(3+n+3*m+2*q){return -1};mut pos:=3;mut spokes:=[max_n]i64{}
  for i in 0..n{spokes[i]=input[pos];pos++;if spokes[i]<0||spokes[i]>max_w{return -1}}
  mut eu:=[max_m]i64{};mut ev:=[max_m]i64{};mut ew:=[max_m]i64{};mut seen:=[max_n][max_n]bool{}
  for e in 0..m{u:=input[pos];v:=input[pos+1];weight:=input[pos+2];pos+=3;if u<0||u>=n0||v<0||v>=n0||u==v||weight<0||weight>max_w{return -1};a:=int(min(u,v));b:=int(max(u,v));if seen[a][b]{return -1};seen[a][b]=true;eu[e]=u;ev[e]=v;ew[e]=weight}
  mut ux:=[max_q]i64{};mut uy:=[max_q]i64{};for i in 0..q{ux[i]=input[pos];uy[i]=input[pos+1];pos+=2;if ux[i]<0||ux[i]>=n0||uy[i]<0||uy[i]>max_w{return -1}}
  bytes:=8*q;if bytes>max_output{return -1};if output==nil||capacity<usize(bytes){return -2};mut answers:=[max_q]i64{}
  for i in 0..q{spokes[int(ux[i])]=uy[i];answers[i]=stoer_wagner(n,spokes[..n],eu[..m],ev[..m],ew[..m],m)}
  for i in 0..q{store_le(mut output,8*i,answers[i])};return i64(bytes)
 }
}
