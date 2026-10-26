import std/math
const MaxN=8
const MaxM=24
const MaxRoots=4
const MaxInput=4+MaxN+MaxM+22*MaxRoots
proc graphai_frontier_sampler*(input:ptr UncheckedArray[float64],length:csize_t,
    output:ptr UncheckedArray[float64],capacity:csize_t):int64 {.cdecl,exportc:"graphai_frontier_sampler".}=
  if input.isNil or length<csize_t(3) or length>csize_t(MaxInput):return -1
  for q in 0..<int(length):if not input[q].isFinite:return -1
  let nv=input[0];let mv=input[1];let rv=input[2]
  if nv!=floor(nv) or mv!=floor(mv) or rv!=floor(rv) or nv<1 or nv>MaxN or mv<0 or mv>MaxM or rv<1 or rv>MaxRoots:return -1
  let n=int(nv);let m=int(mv);let r=int(rv);let required=22*r
  if int(length)!=4+n+m+22*r:return -1
  let rootAt=3;let rowAt=rootAt+r;let colAt=rowAt+n+1;let choiceAt=colAt+m
  var rows:array[MaxN+1,int];var cols:array[MaxM,int];var front:array[MaxRoots*12,int];var next:array[MaxRoots*12,int];var staged:array[MaxRoots*22,float64]
  for i in 0..<r:
    let x=input[rootAt+i];if x!=floor(x) or x<0 or x>=float64(n):return -1
    front[i]=int(x);staged[i]=x
  if input[rowAt]!=0 or input[colAt-1]!=float64(m):return -1
  for i in 0..n:
    let x=input[rowAt+i];if x!=floor(x) or x<0 or x>float64(m):return -1
    rows[i]=int(x);if i>0 and rows[i]<rows[i-1]:return -1
  for e in 0..<m:
    let x=input[colAt+e];if x!=floor(x) or x<0 or x>=float64(n):return -1
    cols[e]=int(x)
  if output.isNil or capacity<csize_t(required):return -2
  let fanouts=[3,2,2]
  var frontSize=r;var choice=0;var outAt=r
  for round in 0..<3:
    let fanout=fanouts[round];let nextSize=frontSize*fanout
    for i in 0..<frontSize:
      let parent=front[i];let begin=rows[parent];let degree=rows[parent+1]-begin
      if degree==0:return -1
      for j in 0..<fanout:
        let x=input[choiceAt+choice];choice+=1
        if x!=floor(x) or x<0 or x>=float64(degree):return -1
        let vertex=cols[begin+int(x)];next[i*fanout+j]=vertex;staged[outAt]=float64(vertex);outAt+=1
    for i in 0..<nextSize:front[i]=next[i]
    frontSize=nextSize
  if choice!=21*r or outAt!=required:return -1
  for q in 0..<required:output[q]=staged[q]
  int64(required)
