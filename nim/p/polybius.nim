proc polybius*(v: ptr UncheckedArray[int64], n: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "polybius".} =
  if v.isNil or n < 1 or n > 65 or v[0] < 0 or v[0] > 64 or n != csize_t(v[0] + 1): return -1
  let count = int(v[0]); let needed = count * 2
  if needed > int(capacity) or (needed > 0 and output.isNil): return -2
  for i in 0..<count:
    var x = v[i + 1]
    if x >= 97 and x <= 122: x -= 32
    if x < 65 or x > 90 or x == 74: return -1
    var index = x - 65
    if x > 74: dec index
    output[i * 2] = uint8(65 + index div 5)
    output[i * 2 + 1] = uint8(65 + index mod 5)
  int64(needed)
