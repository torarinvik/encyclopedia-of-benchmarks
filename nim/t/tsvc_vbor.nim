const MaxN = 128

proc tsvc_vbor*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "tsvc_vbor".} =
  if values.isNil or length < csize_t(7) or length > csize_t(1 + 6 * MaxN): return -1
  let nValue = values[0]
  if nValue < 1 or nValue > MaxN: return -1
  let n = int(nValue)
  if length != csize_t(1 + 6 * n): return -1
  for index in 1 ..< int(length):
    if values[index] < 0 or values[index] > 2: return -1

  var checksum = 0'i64
  for i in 0 ..< n:
    let a = values[1 + i]
    let b = values[1 + n + i]
    let c = values[1 + 2 * n + i]
    let d = values[1 + 3 * n + i]
    let e = values[1 + 4 * n + i]
    let f = values[1 + 5 * n + i]
    let a1 = a*b*c + a*b*d + a*b*e + a*b*f + a*c*d + a*c*e + a*c*f + a*d*e + a*d*f + a*e*f
    let b1 = b*c*d + b*c*e + b*c*f + b*d*e + b*d*f + b*e*f
    let c1 = c*d*e + c*d*f + c*e*f
    let d1 = d*e*f
    checksum += a1*b1*c1*d1
  checksum
