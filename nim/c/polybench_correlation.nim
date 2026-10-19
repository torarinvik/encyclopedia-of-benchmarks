# PolyBench/C correlation bounded port. See benchmarks/c/polybench_correlation/LICENSE.txt.
import std/math
const MaxN=6
const MaxM=6

proc polybench_correlation*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 {.cdecl, exportc: "polybench_correlation".} =
  if input.isNil or length != csize_t(2): return -1
  let nv=input[0];let mv=input[1]
  if not nv.isFinite or not mv.isFinite or nv != floor(nv) or mv != floor(mv) or nv < 1 or nv > float64(MaxN) or mv < 1 or mv > float64(MaxM): return -1
  let n=int(nv);let m=int(mv);let required=m*m
  if output.isNil or capacity<csize_t(required): return -2
  var data: array[36,float64]
  var corr: array[36,float64]
  var mean: array[6,float64]
  var stddev: array[6,float64]
  var staged: array[36,float64]
  let floatN=float64(n)
  for i in 0 ..< n:
    for j in 0 ..< m: data[i*m+j]=float64(i*j)/float64(m)+float64(i)
  for j in 0 ..< m:
    mean[j]=0.0
    for i in 0 ..< n: mean[j]+=data[i*m+j]
    mean[j]/=floatN
  for j in 0 ..< m:
    stddev[j]=0.0
    for i in 0 ..< n:
      let delta=data[i*m+j]-mean[j]
      stddev[j]+=delta*delta
    stddev[j]/=floatN
    stddev[j]=sqrt(stddev[j])
    if stddev[j]<=0.1: stddev[j]=1.0
  let rootN=sqrt(floatN)
  for i in 0 ..< n:
    for j in 0 ..< m:
      data[i*m+j]-=mean[j]
      data[i*m+j]/=rootN*stddev[j]
  if m>1:
    for i in 0 ..< m-1:
      corr[i*m+i]=1.0
      for j in i+1 ..< m:
        corr[i*m+j]=0.0
        for k in 0 ..< n: corr[i*m+j]+=data[k*m+i]*data[k*m+j]
        corr[j*m+i]=corr[i*m+j]
  corr[(m-1)*m+m-1]=1.0
  for q in 0 ..< required: staged[q]=corr[q]
  for q in 0 ..< required: output[q]=staged[q]
  int64(required)
