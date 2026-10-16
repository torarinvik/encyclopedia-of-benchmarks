import math

type C = tuple[r, i: float64]
proc sub(a,b:C): C = (a.r-b.r, a.i-b.i)
proc mul(a,b:C): C = (a.r*b.r-a.i*b.i, a.r*b.i+a.i*b.r)
proc divc(a,b:C): C =
  let den=b.r*b.r+b.i*b.i
  ((a.r*b.r+a.i*b.i)/den, (a.i*b.r-a.r*b.i)/den)
proc mag(a:C): float64 = sqrt(a.r*a.r+a.i*a.i)

proc durand_kerner_roots*(v: ptr UncheckedArray[int64], n: csize_t): float64
    {.cdecl, exportc: "durand_kerner_roots".} =
  if v == nil or n != 3: return -1.0e300
  let d=v[0]; let ri=v[1]; let part=v[2]
  if d == 0 or d < -4 or d > 4 or ri < 0 or ri > 2 or part < 0 or part > 1: return -1.0e300
  let s=if d>0: 1.0 else: -1.0
  let q=sqrt(3.0)/2.0
  var z: array[3,C] = [(s,0.0),(-0.5*s,q*s),(-0.5*s,-q*s)]
  for it in 0..<100:
    var next=z
    var change=0.0
    for i in 0..<3:
      var den:C=(1.0,0.0)
      for j in 0..<3:
        if i != j: den=mul(den,sub(z[i],z[j]))
      let z3=mul(mul(z[i],z[i]),z[i])
      next[i]=sub(z[i],divc(sub(z3,(float64(d),0.0)),den))
      change=max(change,mag(sub(next[i],z[i])))
    z=next
    if change < 1.0e-14: break
  if part == 0: z[ri].r else: z[ri].i
