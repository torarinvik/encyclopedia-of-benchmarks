const InvalidResult = -1.0e300
const Scale = 1_000_000.0
proc sparse_categorical_cross_entropy*(values: ptr UncheckedArray[int64], length: csize_t): float64 {.cdecl, exportc: "sparse_categorical_cross_entropy".} =
  if values==nil or length<2:return InvalidResult
  let batch=values[0];let classes=values[1]
  if batch<1 or batch>32 or classes<1 or classes>32:return InvalidResult
  let b=int(batch);let c=int(classes);if length!=2+b+b*c:return InvalidResult
  for r in 0..<b:
    let label=values[2+r];if label<0 or label>=classes:return InvalidResult
    var rowSum:int64=0
    for col in 0..<c:
      let x=values[2+b+r*c+col];if x<0 or x>1_000_000:return InvalidResult
      rowSum+=x
    if rowSum!=1_000_000:return InvalidResult
  var total=0.0
  for r in 0..<b:
    let idx=2+b+r*c+int(values[2+r]);let p=max(1e-15,float64(values[idx])/Scale);total-=ln(p)
  return total
