## Clean-room bounded sequential GARDENIA MF-SGD profile.
import std/math

proc gardenia_sgd*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 {.cdecl, exportc: "gardenia_sgd".} =
  if input.isNil or length<4 or length>92: return -1
  for q in 0 ..< int(length):
    if not input[q].isFinite: return -1
  let uv=input[0];let iv=input[1];let mv=input[2];let kv=input[3]
  if uv!=floor(uv) or iv!=floor(iv) or mv!=floor(mv) or kv!=floor(kv) or uv<1 or uv>7 or iv<1 or iv>7 or mv<1 or mv>24 or kv<1 or kv>4: return -1
  let users=int(uv);let items=int(iv);let m=int(mv);let k=int(kv);let n=users+items
  if n>8 or int(length)!=5+users+2*m+n*k: return -1
  let rp=4;let ci=rp+users+1;let ra=ci+m;let la=ra+m
  var rows:array[9,int];var cols:array[24,int];var ratings:array[24,float64];var latent:array[32,float64];var errors:array[8,float64];var staged:array[32,float64]
  for i in 0 .. users:
    let z=input[rp+i]
    if z!=floor(z) or z<0 or z>float64(m): return -1
    rows[i]=int(z)
    if i>0 and rows[i]<rows[i-1]: return -1
  if rows[0]!=0 or rows[users]!=m: return -1
  for e in 0 ..< m:
    let z=input[ci+e]
    if z!=floor(z) or z<0 or z>=float64(items): return -1
    cols[e]=int(z);ratings[e]=input[ra+e]
    if ratings[e]< -4 or ratings[e]>4: return -1
  for q in 0 ..< n*k:
    latent[q]=input[la+q]
    if latent[q]<0 or latent[q]>0.1: return -1
  let required=n*k
  if output.isNil or capacity<csize_t(required): return -2
  for _ in 0 ..< 3:
    for u in 0 ..< users: errors[u]=0
    for u in 0 ..< users:
      for e in rows[u] ..< rows[u+1]:
        let v=users+cols[e];var estimate=0.0
        for f in 0 ..< k: estimate+=latent[u*k+f]*latent[v*k+f]
        let delta=ratings[e]-estimate;errors[u]+=delta*delta
        for f in 0 ..< k:
          let ui=u*k+f;let vi=v*k+f;let pu=latent[ui];let pi=latent[vi]
          latent[ui]+=0.00000035*(-0.001*pu+pi*delta)
          latent[vi]+=0.00000035*(-0.001*pi+pu*delta)
    var total=0.0
    for u in 0 ..< users: total+=errors[u]
    if sqrt(total/float64(m))<0.1: break
  for q in 0 ..< required: staged[q]=latent[q]
  for q in 0 ..< required: output[q]=staged[q]
  int64(required)
