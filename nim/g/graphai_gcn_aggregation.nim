import std/math
const MaxN=8
const MaxM=24
const MaxD=4
const MaxInput=4+3*MaxN+MaxM+MaxN*MaxD
proc graphai_gcn_aggregation*(input: ptr UncheckedArray[float64], length:csize_t,
    output:ptr UncheckedArray[float64],capacity:csize_t):int64 {.cdecl,exportc:"graphai_gcn_aggregation".}=
  if input.isNil or length<csize_t(7) or length>csize_t(MaxInput):return -1
  for q in 0..<int(length):if not input[q].isFinite:return -1
  let nv=input[0];let mv=input[1];let dv=input[2]
  if nv!=floor(nv) or mv!=floor(mv) or dv!=floor(dv) or nv<1 or nv>MaxN or mv<0 or mv>MaxM or dv<1 or dv>MaxD:return -1
  let n=int(nv);let m=int(mv);let d=int(dv)
  if int(length)!=4+3*n+m+n*d:return -1
  let oa=3;let ea=oa+n+1;let la=ea+m;let ra=la+n;let fa=ra+n
  if input[oa]!=0 or input[ea-1]!=float64(m):return -1
  var rowptr:array[MaxN+1,int];var colind:array[MaxM,int]
  for i in 0..n:
    let x=input[oa+i];if x!=floor(x) or x<0 or x>float64(m):return -1
    rowptr[i]=int(x);if i>0 and rowptr[i]<rowptr[i-1]:return -1
  for e in 0..<m:
    let x=input[ea+e];if x!=floor(x) or x<0 or x>=float64(n):return -1
    colind[e]=int(x)
  for i in 0..<n:
    if input[la+i]< -4 or input[la+i]>4 or input[ra+i]< -4 or input[ra+i]>4:return -1
  for q in 0..<n*d:if input[fa+q]< -8 or input[fa+q]>8:return -1
  let required=n*d
  if output.isNil or capacity<csize_t(required):return -2
  var staged:array[MaxN*MaxD,float64]
  for src in 0..<n:
    for e in rowptr[src]..<rowptr[src+1]:
      let dst=colind[e];let weight=input[la+src]*input[ra+dst]
      for k in 0..<d:staged[src*d+k]+=weight*input[fa+dst*d+k]
  for q in 0..<required:output[q]=staged[q]
  int64(required)
