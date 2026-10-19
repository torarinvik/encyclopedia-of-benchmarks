# PolyBench/C lu bounded port. See benchmarks/l/polybench_lu/LICENSE.txt.
import std/math
const MaxN=6

proc polybench_lu*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 {.cdecl, exportc: "polybench_lu".} =
  if input.isNil or length != csize_t(1): return -1
  let nv=input[0]
  if not nv.isFinite or nv != floor(nv) or nv < 1 or nv > float64(MaxN): return -1
  let n=int(nv);let cells=n*n
  if output.isNil or capacity<csize_t(cells): return -2
  var a: array[36,float64]
  var base: array[36,float64]
  var staged: array[36,float64]
  for i in 0 ..< n:
    for j in 0 .. i: base[i*n+j]=1.0-float64(j)/float64(n)
    base[i*n+i]=1.0
  for t in 0 ..< n:
    for r in 0 ..< n:
      for s in 0 ..< n: a[r*n+s]+=base[r*n+t]*base[s*n+t]
  for i in 0 ..< n:
    for j in 0 ..< i:
      for k in 0 ..< j: a[i*n+j]-=a[i*n+k]*a[k*n+j]
      a[i*n+j]/=a[j*n+j]
    for j in i ..< n:
      for k in 0 ..< i: a[i*n+j]-=a[i*n+k]*a[k*n+j]
  for q in 0 ..< cells: staged[q]=a[q]
  for q in 0 ..< cells: output[q]=staged[q]
  int64(cells)
