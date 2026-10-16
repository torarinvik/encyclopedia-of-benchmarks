proc number_container_system*(values: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "number_container_system".} =
  if values == nil or length < 1 or values[0] < 0 or values[0] > 32 or int(length) != 1 + 3*int(values[0]): return -1
  var slots: array[64, int64]
  var present: array[64, bool]
  var result = ""
  for i in 0 ..< int(values[0]):
    let op = values[1+3*i]; let a = values[2+3*i]; let b = values[3+3*i]
    if op == 0:
      if a < 0 or a > 63 or b < -100 or b > 100: return -1
      slots[int(a)] = b; present[int(a)] = true
    elif op == 1:
      if a < -100 or a > 100 or b != 0: return -1
      var found = -1'i64
      for j in 0 ..< 64:
        if present[j] and slots[j] == a: found = int64(j); break
      if result.len > 0: result.add(',')
      result.add($found)
    else: return -1
  if result.len > int(capacity) or (result.len > 0 and output == nil): return -2
  for i in 0 ..< result.len: output[i] = uint8(ord(result[i]))
  int64(result.len)
