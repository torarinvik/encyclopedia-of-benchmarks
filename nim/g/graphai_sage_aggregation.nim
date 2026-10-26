import std/math
const MaxN=8
const MaxM=24
const MaxD=4
const MaxInput=4+MaxN+MaxM+MaxN*MaxD
proc graphai_sage_aggregation*(input:ptr UncheckedArray[float64],length:csize_t,
    output:ptr UncheckedArray[float64],capacity:csize_t):int64 {.cdecl,exportc:"graphai_sage_aggregation".}=
  if input.isNil or length<csize_t(4) or length>csize_t(MaxInput):return -1
  for q in 0..<int(length):if not input[q].isFinite:return -1
  let nv=input[0];let mv=input[1];let dv=input[2]
  if nv!=floor(nv) or mv!=floor(mv) or dv!=floor(dv) or nv<1 or nv>MaxN or mv<0 or mv>MaxM or dv<1 or dv>MaxD:return -1
  let n=int(nv);let m=int(mv);let d=int(dv);if int(length)!=4+n+m+n*d:return -1
  let rp=3;let ci=rp+n+1;let xf=ci+m;if input[rp]!=0 or input[ci-1]!=float64(m):return -1
  var rows:array[MaxN+1,int];var cols:array[MaxM,int]
  for i in 0..n:
    let x=input[rp+i];if x!=floor(x) or x<0 or x>float64(m):return -1
    rows[i]=int(x);if i>0 and rows[i]<rows[i-1]:return -1
  for e in 0..<m:
    let x=input[ci+e];if x!=floor(x) or x<0 or x>=float64(n):return -1
    cols[e]=int(x)
  for q in 0..<n*d:if input[xf+q]< -8 or input[xf+q]>8:return -1
  let required=n*d;if output.isNil or capacity<csize_t(required):return -2
  var staged:array[MaxN*MaxD,float64]
  for src in 0..<n:
    let degree=rows[src+1]-rows[src]
    if degree>0:
      let scale=1.0/float64(degree)
      for e in rows[src]..<rows[src+1]:
        let dst=cols[e]
        for k in 0..<d:staged[src*d+k]+=scale*input[xf+dst*d+k]
  for q in 0..<required:output[q]=staged[q]
  int64(required)
