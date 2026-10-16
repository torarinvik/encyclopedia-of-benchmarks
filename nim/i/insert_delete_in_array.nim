proc insert_delete_in_array*(v: ptr UncheckedArray[int64], n: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "insert_delete_in_array".} =
  if v == nil or n < 4 or n > 260: return -1
  let op=v[0]; let length=v[1]; let pos=v[2]; let element=v[3]
  if (op != 0 and op != 1) or length < 0 or length > 256 or n != csize_t(length + 4) or pos < 0: return -1
  if (op == 0 and pos > length) or (op == 1 and pos >= length) or (op == 1 and element != 0): return -1
  for i in 0 ..< int(length):
    if v[i+4] < low(int32).int64 or v[i+4] > high(int32).int64: return -1
  if op == 0 and (element < low(int32).int64 or element > high(int32).int64): return -1
  let outn = int(length) + (if op == 0: 1 else: 0)
  if outn * 4 > int(capacity) or (outn > 0 and output == nil): return -2
  for i in 0 ..< outn:
    var x: int64
    if op == 0: x = if i < int(pos): v[i+4] elif i == int(pos): element else: v[i+3]
    else: x = if i < int(pos): v[i+4] else: v[i+5]
    let word = uint32(int32(x))
    output[i*4] = uint8(word and 255); output[i*4+1] = uint8((word shr 8) and 255)
    output[i*4+2] = uint8((word shr 16) and 255); output[i*4+3] = uint8((word shr 24) and 255)
  int64(outn * 4)
