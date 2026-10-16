module edmonds
const nmax = 5
const emax = 12
const inf = i64(1_000_000_000)
@[export: 'edmonds']
pub fn edmonds(a &i64, length usize) i64 {
 if unsafe { a == nil } || length < 3 || length > 39 { return -1 }
 n64:=unsafe{a[0]}; root64:=unsafe{a[1]}; m64:=unsafe{a[2]}
 if n64<1||n64>nmax||root64<0||root64>=n64||m64<0||m64>emax||length!=usize(3+3*m64){return -1}
 mut n:=int(n64);mut root:=int(root64);m:=int(m64)
 mut eu:=[]int{len:emax};mut ev:=[]int{len:emax};mut ew:=[]i64{len:emax}
 for i in 0..m {u:=unsafe{a[3+3*i]};v:=unsafe{a[4+3*i]};w:=unsafe{a[5+3*i]};if u<0||u>=n64||v<0||v>=n64||w<0||w>100{return -1};eu[i]=int(u);ev[i]=int(v);ew[i]=w}
 mut answer:=i64(0)
 for {
  mut inn:=[]i64{len:nmax};mut pre:=[]int{len:nmax}
  for i in 0..n {inn[i]=inf;pre[i]=-1}
  for i in 0..m {if eu[i]!=ev[i] && ev[i]!=root && ew[i]<inn[ev[i]]{inn[ev[i]]=ew[i];pre[ev[i]]=eu[i]}}
  inn[root]=0;for i in 0..n {if inn[i]==inf{return -1}}
  mut ids:=[]int{len:nmax};mut vis:=[]int{len:nmax}
  for i in 0..n {ids[i]=-1;vis[i]=-1}
  mut cycles:=0
  for i in 0..n {answer+=inn[i];mut v:=i;for vis[v]!=i && ids[v]==-1 && v!=root{vis[v]=i;v=pre[v]};if v!=root && ids[v]==-1{mut u:=pre[v];for u!=v{ids[u]=cycles;u=pre[u]};ids[v]=cycles;cycles++}}
  if cycles==0{return answer}
  for i in 0..n {if ids[i]==-1{ids[i]=cycles;cycles++}}
  for i in 0..m {oldv:=ev[i];u:=ids[eu[i]];v:=ids[oldv];if u!=v{ew[i]-=inn[oldv]};eu[i]=u;ev[i]=v}
  root=ids[root];n=cycles
 }
 return answer
}
