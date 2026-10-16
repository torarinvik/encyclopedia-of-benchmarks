package edmonds
import "core:c"
NMAX :: 5
EMAX :: 12
INF :: i64(1_000_000_000)
@(export)
edmonds :: proc "c" (a: [^]i64, length: c.size_t) -> i64 {
 if a==nil || length<3 || length>39 do return -1
 n64:=a[0]; root64:=a[1]; m64:=a[2]
 if n64<1 || n64>NMAX || root64<0 || root64>=n64 || m64<0 || m64>EMAX || int(length)!=3+3*int(m64) do return -1
 n:=int(n64); root:=int(root64); m:=int(m64)
 eu: [EMAX]int; ev: [EMAX]int; ew: [EMAX]i64
 for i:=0;i<m;i+=1 {u:=a[3+3*i];v:=a[4+3*i];w:=a[5+3*i];if u<0||u>=n64||v<0||v>=n64||w<0||w>100 do return -1;eu[i]=int(u);ev[i]=int(v);ew[i]=w}
 answer:=i64(0)
 for {
  inn: [NMAX]i64; pre: [NMAX]int
  for i:=0;i<n;i+=1 {inn[i]=INF;pre[i]=-1}
  for i:=0;i<m;i+=1 {if eu[i]!=ev[i]&&ev[i]!=root&&ew[i]<inn[ev[i]] {inn[ev[i]]=ew[i];pre[ev[i]]=eu[i]}}
  inn[root]=0;for i:=0;i<n;i+=1 {if inn[i]==INF do return -1}
  ids: [NMAX]int; vis: [NMAX]int
  for i:=0;i<n;i+=1 {ids[i]=-1;vis[i]=-1}
  cycles:=0
  for i:=0;i<n;i+=1 {answer+=inn[i];v:=i;for vis[v]!=i&&ids[v]==-1&&v!=root {vis[v]=i;v=pre[v]};if v!=root&&ids[v]==-1 {u:=pre[v];for u!=v {ids[u]=cycles;u=pre[u]};ids[v]=cycles;cycles+=1}}
  if cycles==0 do return answer
  for i:=0;i<n;i+=1 {if ids[i]==-1 {ids[i]=cycles;cycles+=1}}
  for i:=0;i<m;i+=1 {oldv:=ev[i];u:=ids[eu[i]];v:=ids[oldv];if u!=v {ew[i]-=inn[oldv]};eu[i]=u;ev[i]=v}
  root=ids[root];n=cycles
 }
 return answer
}
