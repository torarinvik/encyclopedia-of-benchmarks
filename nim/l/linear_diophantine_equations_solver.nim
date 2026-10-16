proc linear_diophantine_equations_solver*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "linear_diophantine_equations_solver".} =
  if v.isNil or n != 3: return -1
  let a=v[0]; let b=v[1]; let c=v[2]
  if abs(a)>1000 or abs(b)>1000 or abs(c)>10000: return -1
  if a==0 and b==0: return (if c==0: -3 else: -2)
  if a==0: return (if c mod b==0: 20000003*(10000001)+(c div b+10000001) else: -2)
  if b==0: return (if c mod a==0: (c div a+10000001)*20000003+10000001 else: -2)
  var oldR=a; var r=b; var oldS=1'i64; var s=0'i64; var oldT=0'i64; var t=1'i64
  while r!=0:
    let q=oldR div r
    let z=oldR-q*r; oldR=r; r=z
    let z2=oldS-q*s; oldS=s; s=z2
    let z3=oldT-q*t; oldT=t; t=z3
  if c mod oldR != 0: return -2
  let x=oldS*(c div oldR); let y=oldT*(c div oldR)
  (x+10000001)*20000003+(y+10000001)
