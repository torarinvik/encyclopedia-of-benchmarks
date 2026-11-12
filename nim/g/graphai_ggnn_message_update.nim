import std/math

const MaxN=8
const MaxM=24
const MaxD=4
const MaxInput=453

proc graphai_ggnn_message_update*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "graphai_ggnn_message_update".} =
  if input.isNil or length<csize_t(3) or length>csize_t(MaxInput): return -1
  for q in 0..<int(length):
    if not input[q].isFinite: return -1
  let nv=input[0]; let mv=input[1]; let dv=input[2]
  if nv!=floor(nv) or mv!=floor(mv) or dv!=floor(dv) or nv<1 or nv>MaxN or mv<0 or mv>MaxM or dv<1 or dv>MaxD: return -1
  let n=int(nv); let m=int(mv); let d=int(dv)
  if int(length)!=4+n+m+n*d+6*n*n: return -1
  let rowAt=3; let colAt=rowAt+n+1; let hAt=colAt+m
  let wzAt=hAt+n*d; let wrAt=wzAt+n*n; let wcAt=wrAt+n*n
  let uzAt=wcAt+n*n; let urAt=uzAt+n*n; let ucAt=urAt+n*n
  if input[rowAt]!=0 or input[colAt-1]!=float64(m): return -1
  var rows: array[MaxN+1,int]; var cols: array[MaxM,int]
  for i in 0..n:
    let x=input[rowAt+i]
    if x!=floor(x) or x<0 or x>float64(m): return -1
    rows[i]=int(x)
    if i>0 and rows[i]<rows[i-1]: return -1
  for e in 0..<m:
    let x=input[colAt+e]
    if x!=floor(x) or x<0 or x>=float64(n): return -1
    cols[e]=int(x)
  for q in hAt..<wzAt:
    if input[q]< -1 or input[q]>1: return -1
  for q in wzAt..<int(length):
    if input[q]< -0.25 or input[q]>0.25: return -1
  let required=n*d
  if output.isNil or capacity<csize_t(required): return -2
  var aggregate: array[MaxN*MaxD,float64]
  var update: array[MaxN*MaxD,float64]
  var reset: array[MaxN*MaxD,float64]
  var candidate: array[MaxN*MaxD,float64]
  var staged: array[MaxN*MaxD,float64]
  for v in 0..<n:
    for e in rows[v]..<rows[v+1]:
      for f in 0..<d: aggregate[v*d+f]+=input[hAt+cols[e]*d+f]
  for v in 0..<n:
    for f in 0..<d:
      var wz=0.0; var wr=0.0; var uz=0.0; var ur=0.0
      for k in 0..<n:
        let a=v*n+k; let b=k*d+f
        wz+=input[wzAt+a]*aggregate[b]; wr+=input[wrAt+a]*aggregate[b]
        uz+=input[uzAt+a]*input[hAt+b]; ur+=input[urAt+a]*input[hAt+b]
      let at=v*d+f
      update[at]=1.0/(1.0+exp(-(wz+uz)))
      reset[at]=1.0/(1.0+exp(-(wr+ur)))
  for v in 0..<n:
    for f in 0..<d:
      var fromGraph=0.0; var fromState=0.0
      for k in 0..<n:
        let a=v*n+k; let b=k*d+f
        fromGraph+=input[wcAt+a]*aggregate[b]
        fromState+=input[ucAt+a]*(reset[b]*input[hAt+b])
      let at=v*d+f; let x=fromGraph+fromState
      candidate[at]=2.0/(1.0+exp(-2.0*x))-1.0
      staged[at]=(1.0-update[at])*input[hAt+at]+update[at]*candidate[at]
  for q in 0..<required: output[q]=staged[q]
  int64(required)
