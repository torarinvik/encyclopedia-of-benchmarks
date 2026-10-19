# PolyBench/C seidel-2d bounded port. See benchmarks/s/polybench_seidel_2d/LICENSE.txt.
import std/math
const MaxN=6

proc polybench_seidel_2d*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 {.cdecl, exportc: "polybench_seidel_2d".} =
  if input.isNil or length != csize_t(2): return -1
  let nv=input[0];let sv=input[1]
  if not nv.isFinite or not sv.isFinite or nv != floor(nv) or sv != floor(sv) or nv < 1 or nv > float64(MaxN) or sv < 0 or sv > 4: return -1
  let n=int(nv);let steps=int(sv);let cells=n*n
  if output.isNil or capacity<csize_t(cells): return -2
  var a: array[36,float64]
  var staged: array[36,float64]
  for i in 0 ..< n:
    for j in 0 ..< n: a[i*n+j]=(float64(i)*float64(j+2)+2.0)/float64(n)
  for step in 0 ..< steps:
    if n>2:
      for i in 1 ..< n-1:
        for j in 1 ..< n-1:
          let q=i*n+j
          let total=a[q-n-1]+a[q-n]+a[q-n+1]+a[q-1]+a[q]+a[q+1]+a[q+n-1]+a[q+n]+a[q+n+1]
          a[q]=total/9.0
  for q in 0 ..< cells: staged[q]=a[q]
  for q in 0 ..< cells: output[q]=staged[q]
  int64(cells)
