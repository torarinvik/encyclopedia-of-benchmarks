proc pig_latin*(v: ptr UncheckedArray[int64], n: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "pig_latin".} =
  if v.isNil or n < 1 or n > 65 or v[0] < 0 or v[0] > 64 or n != csize_t(v[0] + 1): return -1
  let count = int(v[0]); if count == 0: return 0
  if count + 3 > int(capacity) or output.isNil: return -2
  var pivot = count
  for i in 0..<count:
    var x = v[i + 1]
    if x >= 65 and x <= 90: x += 32
    if x < 97 or x > 122: return -1
    output[i] = uint8(x)
    if pivot == count and x in [97'i64, 101'i64, 105'i64, 111'i64, 117'i64]: pivot = i
  if pivot == count: return -1
  if pivot == 0:
    output[count] = uint8('w'); output[count + 1] = uint8('a'); output[count + 2] = uint8('y')
    return int64(count + 3)
  for i in 0..<pivot: output[count + i] = output[i]
  for i in 0..<(count - pivot): output[i] = output[pivot + i]
  output[count] = uint8('a'); output[count + 1] = uint8('y')
  int64(count + 2)
