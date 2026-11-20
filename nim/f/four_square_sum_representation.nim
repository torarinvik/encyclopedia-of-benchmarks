proc floorSqrt(value: int64): int64 =
  var root = 0'i64
  while (root + 1) * (root + 1) <= value:
    inc root
  root

proc four_square_sum_representation*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "four_square_sum_representation".} =
  if input.isNil or length != csize_t(1): return -1
  let n = input[0]
  if n < 0 or n > 1024: return -1

  var a = floorSqrt(n)
  while a >= 0:
    let remainderA = n - a * a
    var bMax = floorSqrt(remainderA)
    if bMax > a: bMax = a
    var b = bMax
    while b >= 0:
      let remainderB = remainderA - b * b
      var cMax = floorSqrt(remainderB)
      if cMax > b: cMax = b
      var c = cMax
      while c >= 0:
        let remainderC = remainderB - c * c
        let d = floorSqrt(remainderC)
        if d <= c and d * d == remainderC:
          return (((a * 33 + b) * 33 + c) * 33 + d)
        dec c
      dec b
    dec a
  -2
