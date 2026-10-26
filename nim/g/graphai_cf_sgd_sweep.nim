import std/math
const MaxN=8
const MaxM=24
const MaxK=4
const MaxInput=7+MaxN+2*MaxM+MaxN*MaxK
proc graphai_cf_sgd_sweep*(input:ptr UncheckedArray[float64],length:csize_t,
    output:ptr UncheckedArray[float64],capacity:csize_t):int64 {.cdecl,exportc:"graphai_cf_sgd_sweep".}=
  if input.isNil or length<csize_t(6) or length>csize_t(MaxInput):return -1
  for q in 0..<int(length):if not input[q].isFinite:return -1
  let uv=input[0];let iv=input[1];let mv=input[2];let kv=input[3]
  if uv!=floor(uv) or iv!=floor(iv) or mv!=floor(mv) or kv!=floor(kv) or uv<1 or uv>7 or iv<1 or iv>7 or mv<0 or mv>MaxM or kv<1 or kv>MaxK:return -1
  let users=int(uv);let items=int(iv);let n=users+items;let m=int(mv);let k=int(kv);let lambda=input[4];let step=input[5]
  if n>MaxN or lambda<0 or lambda>1 or step<0 or step>0.01 or int(length)!=7+n+2*m+n*k:return -1
  let rp=6;let ci=rp+n+1;let ra=ci+m;let la=ra+m
  if input[rp]!=0 or input[ci-1]!=float64(m):return -1
  var rows:array[MaxN+1,int];var cols:array[MaxM,int]
  for i in 0..n:
    let x=input[rp+i];if x!=floor(x) or x<0 or x>float64(m):return -1
    rows[i]=int(x);if i>0 and rows[i]<rows[i-1]:return -1
  for u in users..<n:if rows[u]!=rows[u+1]:return -1
  for e in 0..<m:
    let x=input[ci+e];if x!=floor(x) or x<float64(users) or x>=float64(n):return -1
    cols[e]=int(x)
  for e in 0..<m:if input[ra+e]< -4 or input[ra+e]>4:return -1
  for q in 0..<n*k:if input[la+q]< -2 or input[la+q]>2:return -1
  let required=n*k;if output.isNil or capacity<csize_t(required):return -2
  var errors:array[MaxN*MaxK,float64];var staged:array[MaxN*MaxK,float64]
  for u in 0..<users:
    for edge in rows[u]..<rows[u+1]:
      let v=cols[edge];var estimate=0.0
      for j in 0..<k:estimate+=input[la+u*k+j]*input[la+v*k+j]
      let delta=input[ra+edge]-estimate
      for j in 0..<k:errors[u*k+j]+=input[la+v*k+j]*delta
  for v in 0..<n:
    for j in 0..<k:
      let q=v*k+j;staged[q]=input[la+q]+step*(-lambda*input[la+q]+errors[q])
  for q in 0..<required:output[q]=staged[q]
  int64(required)
