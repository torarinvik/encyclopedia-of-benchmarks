// Boruvka minimum spanning tree total for a bounded connected undirected graph.
@[export: 'boruvkas_minimum_spanning_tree']
pub fn boruvkas_minimum_spanning_tree(input &i64, length usize) i64 {
 if length<2{return -1}
 unsafe {
  nv:=input[0];mv:=input[1]
  if nv<2||nv>16||mv<nv-1||mv>64||mv>nv*(nv-1)/2{return -1}
  n:=int(nv);m:=int(mv);if length!=usize(2+3*m){return -1}
  mut w:=[][]i64{len:n,init:[]i64{len:n,init:i64(9223372036854775807)}}
  for k:=0;k<m;k++ {u:=input[2+3*k];v:=input[3+3*k];x:=input[4+3*k];if u<1||u>nv||v<1||v>nv||u==v||x<1||x>100||w[int(u-1)][int(v-1)]!=i64(9223372036854775807){return -1};w[int(u-1)][int(v-1)]=x;w[int(v-1)][int(u-1)]=x}
  mut p:=[]int{len:n};for i:=0;i<n;i++{p[i]=i};mut components:=n;mut total:=i64(0)
  for components>1 {mut bu:=[]int{len:n,init:-1};mut bv:=[]int{len:n,init:-1};mut bw:=[]i64{len:n,init:i64(9223372036854775807)}
   for u:=0;u<n;u++ {for v:=u+1;v<n;v++ {x:=w[u][v];if x!=i64(9223372036854775807){mut a:=u;for p[a]!=a{p[a]=p[p[a]];a=p[a]};mut b:=v;for p[b]!=b{p[b]=p[p[b]];b=p[b]};if a!=b{if x<bw[a]{bw[a]=x;bu[a]=u;bv[a]=v};if x<bw[b]{bw[b]=x;bu[b]=u;bv[b]=v}}}}}
   mut merged:=false;for r:=0;r<n;r++{if bu[r]>=0{mut a:=bu[r];for p[a]!=a{p[a]=p[p[a]];a=p[a]};mut b:=bv[r];for p[b]!=b{p[b]=p[p[b]];b=p[b]};if a!=b{p[a]=b;components--;total+=bw[r];merged=true}}};if !merged{return -1}
  }
  return total
 }
}
