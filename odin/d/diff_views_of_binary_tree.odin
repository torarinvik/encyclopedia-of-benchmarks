package diff_views_of_binary_tree
import "core:c"
N :: 1023
@(export)
diff_views_of_binary_tree :: proc "c" (a: [^]i64, n0: c.size_t, root: i64, view: i64, out: [^]i64, cap0: c.size_t) -> i64 {
 n:=int(n0); cap:=int(cap0)
 if n>N || view<0 || view>3 do return -1
 if n==0 { if root == -1 do return 0; return -1 }
 if a==nil || root<0 || root>=i64(n) do return -1
 if out==nil || cap<n do return -2
 parents:[N]int
 for i:=0;i<n;i+=1 {
  v,l,r:=a[3*i],a[3*i+1],a[3*i+2]
  if v<i64(-2147483648)||v>i64(2147483647)||l< -1||r< -1||l>=i64(n)||r>=i64(n) do return -1
  if l>=0 {parents[int(l)]+=1;if parents[int(l)]>1 do return -1}
  if r>=0 {parents[int(r)]+=1;if parents[int(r)]>1 do return -1}
 }
 rr:=int(root);if parents[rr]!=0 do return -1
 for i:=0;i<n;i+=1 do if i!=rr&&parents[i]!=1 do return -1
 q,depth:[N]int; col:[N]int; seen:[N]bool; fd,ld:[N]i64;fc,lc:[2*N+1]i64
 sentinel:=i64(-9223372036854775807)
 for i:=0;i<N;i+=1 {fd[i]=sentinel;ld[i]=sentinel}
 for i:=0;i<2*N+1;i+=1 {fc[i]=sentinel;lc[i]=sentinel}
 head,tail,maxd,minc,maxc:=0,1,0,0,0;q[0]=rr;seen[rr]=true
 for head<tail {
  u:=q[head];head+=1;d:=depth[u];cc:=col[u];v:=a[3*u]
  if d>maxd do maxd=d;if cc<minc do minc=cc;if cc>maxc do maxc=cc
  if fd[d]==sentinel do fd[d]=v;ld[d]=v;s:=cc+N;if fc[s]==sentinel do fc[s]=v;lc[s]=v
  l,r:=a[3*u+1],a[3*u+2]
  if l>=0 {x:=int(l);if seen[x]||tail>=n do return -1;seen[x]=true;depth[x]=d+1;col[x]=cc-1;q[tail]=x;tail+=1}
  if r>=0 {x:=int(r);if seen[x]||tail>=n do return -1;seen[x]=true;depth[x]=d+1;col[x]=cc+1;q[tail]=x;tail+=1}
 }
 if tail!=n do return -1
 w:=0
 if view<2 {for d:=0;d<=maxd;d+=1 {v:=fd[d];if view==0 do v=ld[d];if v!=sentinel {out[w]=v;w+=1}}}
 else {for cc:=minc;cc<=maxc;cc+=1 {v:=fc[cc+N];if view==3 do v=lc[cc+N];if v!=sentinel {out[w]=v;w+=1}}}
 return i64(w)
}
