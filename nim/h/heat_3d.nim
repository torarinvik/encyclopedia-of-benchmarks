# PolyBench/C heat-3d bounded port. See benchmarks/h/heat_3d/LICENSE.txt.
import std/math
const MaxN=6

proc polybench_heat_3d*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 {.cdecl, exportc: "polybench_heat_3d".} =
  if input.isNil or length != csize_t(2): return -1
  let nv=input[0]; let sv=input[1]
  if not nv.isFinite or not sv.isFinite or nv != floor(nv) or sv != floor(sv) or nv < 1 or nv > float64(MaxN) or sv < 0 or sv > 4: return -1
  let n=int(nv); let steps=int(sv); let cells=n*n*n
  if output.isNil or capacity < csize_t(cells): return -2
  var a: array[216,float64]
  var b: array[216,float64]
  var staged: array[216,float64]
  for i in 0 ..< n:
    for j in 0 ..< n:
      for k in 0 ..< n:
        let q=i*n*n+j*n+k
        a[q]=float64(i+j+(n-k))*10.0/float64(n)
        b[q]=a[q]
  for step in 0 ..< steps:
    if n > 2:
      for i in 1 ..< n-1:
        for j in 1 ..< n-1:
          for k in 1 ..< n-1:
            let q=i*n*n+j*n+k
            let center=a[q]
            b[q]=0.125*(a[q+n*n]-2.0*center+a[q-n*n])+0.125*(a[q+n]-2.0*center+a[q-n])+0.125*(a[q+1]-2.0*center+a[q-1])+center
      for i in 1 ..< n-1:
        for j in 1 ..< n-1:
          for k in 1 ..< n-1:
            let q=i*n*n+j*n+k
            let center=b[q]
            a[q]=0.125*(b[q+n*n]-2.0*center+b[q-n*n])+0.125*(b[q+n]-2.0*center+b[q-n])+0.125*(b[q+1]-2.0*center+b[q-1])+center
  for q in 0 ..< cells: staged[q]=a[q]
  for q in 0 ..< cells: output[q]=staged[q]
  int64(cells)
