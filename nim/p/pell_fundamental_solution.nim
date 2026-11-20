proc pell_fundamental_solution*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "pell_fundamental_solution".} =
  if values == nil or length != 1: return -1
  let d = values[0]
  if d < 2 or d > 31: return -1

  var root = 1'i64
  while (root + 1) * (root + 1) <= d:
    inc root
  if root * root == d: return -1

  var m = 0'i64
  var denominator = 1'i64
  var a = root
  var hTwoBack = 0'i64
  var hPrevious = 1'i64
  var qTwoBack = 1'i64
  var qPrevious = 0'i64

  while true:
    let x = a * hPrevious + hTwoBack
    let y = a * qPrevious + qTwoBack
    if x * x - d * y * y == 1:
      return x * (1'i64 shl 32) + y

    hTwoBack = hPrevious
    hPrevious = x
    qTwoBack = qPrevious
    qPrevious = y

    m = denominator * a - m
    denominator = (d - m * m) div denominator
    a = (root + m) div denominator
