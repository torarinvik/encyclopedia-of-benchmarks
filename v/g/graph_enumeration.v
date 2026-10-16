module graph_enumeration

@[export: 'graph_enumeration']
pub fn graph_enumeration(a &i64, length int) i64 {
    if unsafe { a == nil } || length < 1 { return -1 }
    n0:=unsafe { a[0] };if n0<0 || n0>16 || length<1+int(n0){return -1};n:=int(n0)
    mut labels:=[16]i64{};mut sorted:=[16]i64{};mut adj:=[16][32]i64{};mut degree:=[16]int{}
    for i in 0..n { labels[i]=unsafe { a[1+i] };if labels[i] < -1000000 || labels[i]>1000000{return -1};for j in 0..i{if labels[i]==labels[j]{return -1}};sorted[i]=labels[i] }
    for i in 0..n { for j in i+1..n {if sorted[j]<sorted[i]{t:=sorted[i];sorted[i]=sorted[j];sorted[j]=t}} }
    mut off:=1+n
    for i in 0..n {if off>=length{return -1};d:=unsafe { a[off] };off++;if d<0 || d>32 || off+int(d)>length{return -1};degree[i]=int(d);for j in 0..int(d){v:=unsafe { a[off] };off++;mut found:=false;for k in 0..n{if labels[k]==v{found=true}};if !found{return -1};adj[i][j]=v}}
    if off!=length{return -1};mut h:=u64(14695981039346656037)
    mix:=fn (hash u64,v i64) u64 {mut out:=hash;mut z:=u64(v);for _ in 0..8{out=(out^ (z&255))*u64(1099511628211);z>>=8};return out}
    h=mix(h,i64(n+1));h=mix(h,0)
    for s in 0..n {mut i:=0;for labels[i]!=sorted[s]{i++};h=mix(h,i64(degree[i]));for j in 0..degree[i]{mut k:=0;for sorted[k]!=adj[i][j]{k++};h=mix(h,i64(k+1))}}
    return i64(h)
}
