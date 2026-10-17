proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc simplest_radical_form*(values: ptr UncheckedArray[int64], length: csize_t,
                            output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "simplest_radical_form".} =
  if values == nil or length != 1: return -1
  let original = values[0]
  if original < 0 or original > 100000000: return -1
  if output == nil or capacity < 16: return -2

  var coefficient = 1'i64
  var rootTerm = 1'i64
  if original == 0:
    rootTerm = 0
  else:
    var remainder = original
    var factor = 2'i64
    while factor * factor <= original:
      var count = 0'i64
      while remainder mod factor == 0:
        remainder = remainder div factor
        count += 1
      for _ in 0 ..< int(count div 2): coefficient *= factor
      if count mod 2 != 0: rootTerm *= factor
      factor += 1
    rootTerm *= remainder
  putI64(output, 0, coefficient)
  putI64(output, 8, rootTerm)
  16
