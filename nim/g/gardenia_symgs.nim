## Clean-room bounded GARDENIA SymGS profile.
import std/math

const NMax = 8
const MMax = 64
const InputMax = 173

proc gardenia_symgs*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 {.cdecl, exportc: "gardenia_symgs".} =
  if input.isNil or length < 3 or length > csize_t(InputMax): return -1
  for q in 0 ..< int(length):
    if not input[q].isFinite: return -1
  let nd=input[0];let md=input[1];let cd=input[2]
  if nd!=floor(nd) or md!=floor(md) or cd!=floor(cd) or nd<1 or nd>float64(NMax) or md<1 or md>float64(MMax) or cd<1 or cd>nd: return -1
  let n=int(nd);let m=int(md);let colors=int(cd)
  if int(length)!=5+4*n+colors+2*m: return -1
  let oa=3;let fa=oa+n;let ra=fa+colors+1;let ca=ra+n+1;let va=ca+m;let xa=va+m;let ba=xa+n
  var order:array[NMax,int];var offsets:array[NMax+1,int];var rows:array[NMax+1,int];var cols:array[MMax,int];var group:array[NMax,int]
  var mat:array[MMax,float64];var x:array[NMax,float64];var rhs:array[NMax,float64];var staged:array[NMax,float64];var seen:array[NMax,bool]
  for i in 0 ..< n:
    let z=input[oa+i]
    if z!=floor(z) or z<0 or z>=nd or seen[int(z)]: return -1
    order[i]=int(z);seen[order[i]]=true
  for k in 0 .. colors:
    let z=input[fa+k]
    if z!=floor(z) or z<0 or z>nd: return -1
    offsets[k]=int(z)
  if offsets[0]!=0 or offsets[colors]!=n: return -1
  for k in 0 ..< colors:
    if offsets[k]>=offsets[k+1]: return -1
    for p in offsets[k] ..< offsets[k+1]: group[order[p]]=k
  for i in 0 .. n:
    let z=input[ra+i]
    if z!=floor(z) or z<0 or z>md: return -1
    rows[i]=int(z)
    if i>0 and rows[i]<rows[i-1]: return -1
  if rows[0]!=0 or rows[n]!=m: return -1
  for u in 0 ..< n:
    var diag=0;var d=0.0;var offsum=0.0;var prev=0
    for e in rows[u] ..< rows[u+1]:
      let z=input[ca+e]
      if z!=floor(z) or z<0 or z>=nd: return -1
      cols[e]=int(z)
      if e>rows[u] and cols[e]<=prev: return -1
      prev=cols[e];mat[e]=input[va+e]
      if mat[e]< -4 or mat[e]>4: return -1
      if cols[e]==u: inc diag;d=mat[e]
      else:
        if group[u]==group[cols[e]]: return -1
        offsum+=abs(mat[e])
    if diag!=1 or d<=offsum: return -1
    for e in rows[u] ..< rows[u+1]:
      let v=cols[e];var found=false
      for f in rows[v] ..< rows[v+1]:
        if cols[f]==u:
          if mat[f]!=mat[e]: return -1
          found=true;break
      if not found: return -1
  for i in 0 ..< n:
    x[i]=input[xa+i];rhs[i]=input[ba+i]
    if x[i]< -4 or x[i]>4 or rhs[i]< -4 or rhs[i]>4: return -1
  if output.isNil or capacity<csize_t(n): return -2
  for pass in 0 .. 1:
    for step in 0 ..< colors:
      let k=if pass==0: step else: colors-1-step
      for p in offsets[k] ..< offsets[k+1]:
        let u=order[p];var sum=0.0;var d=0.0
        for e in rows[u] ..< rows[u+1]:
          let v=cols[e]
          if v==u: d=mat[e]
          else: sum+=x[v]*mat[e]
        if d!=0: x[u]=(rhs[u]-sum)/d
  for i in 0 ..< n: staged[i]=x[i]
  for i in 0 ..< n: output[i]=staged[i]
  int64(n)
