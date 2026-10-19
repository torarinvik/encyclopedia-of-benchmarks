# PolyBench/C fdtd-2d bounded port. See benchmarks/f/fdtd_2d/LICENSE.txt.
import std/math
const MaxNx=6
const MaxNy=6
const MaxTmax=4

proc fdtd_2d*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 {.cdecl, exportc: "fdtd_2d".} =
  if input.isNil or length != csize_t(3): return -1
  let tValue=input[0]; let xValue=input[1]; let yValue=input[2]
  if not tValue.isFinite or not xValue.isFinite or not yValue.isFinite or
      tValue != floor(tValue) or xValue != floor(xValue) or yValue != floor(yValue) or
      tValue < 0 or tValue > float64(MaxTmax) or xValue < 1 or xValue > float64(MaxNx) or
      yValue < 1 or yValue > float64(MaxNy): return -1
  let tmax=int(tValue); let nx=int(xValue); let ny=int(yValue)
  let n=nx*ny; let required=3*n
  if output.isNil or capacity < csize_t(required): return -2
  var ex: array[36,float64]
  var ey: array[36,float64]
  var hz: array[36,float64]
  var fict: array[4,float64]
  var staged: array[108,float64]
  for t in 0 ..< tmax: fict[t]=float64(t)
  for i in 0 ..< nx:
    for j in 0 ..< ny:
      ex[i*ny+j]=float64(i*(j+1))/float64(nx)
      ey[i*ny+j]=float64(i*(j+2))/float64(ny)
      hz[i*ny+j]=float64(i*(j+3))/float64(nx)
  for t in 0 ..< tmax:
    for j in 0 ..< ny: ey[j]=fict[t]
    for i in 1 ..< nx:
      for j in 0 ..< ny: ey[i*ny+j]=ey[i*ny+j]-0.5*(hz[i*ny+j]-hz[(i-1)*ny+j])
    for i in 0 ..< nx:
      for j in 1 ..< ny: ex[i*ny+j]=ex[i*ny+j]-0.5*(hz[i*ny+j]-hz[i*ny+j-1])
    for i in 0 ..< nx-1:
      for j in 0 ..< ny-1: hz[i*ny+j]=hz[i*ny+j]-0.7*((ex[i*ny+j+1]-ex[i*ny+j])+(ey[(i+1)*ny+j]-ey[i*ny+j]))
  for i in 0 ..< n:
    staged[i]=ex[i]
    staged[n+i]=ey[i]
    staged[2*n+i]=hz[i]
  for i in 0 ..< required: output[i]=staged[i]
  int64(required)
