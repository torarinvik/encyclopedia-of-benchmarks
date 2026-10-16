proc elementary*(v: ptr UncheckedArray[int64], n: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "elementary".} =
  if v == nil or n < 2 or n > 129: return -1
  let count = v[0]
  if count < 1 or count > 128 or n != csize_t(count + 1) or v[1] != 0: return -1
  for i in 1 ..< int(n):
    if v[i] != 0 and v[i] != 1: return -1
  if capacity < csize_t(count) or output == nil: return -2
  for i in 0 ..< int(count):
    let left = if i > 0: uint32(v[i]) else: 0'u32
    let center = uint32(v[i + 1])
    let right = if i + 1 < int(count): uint32(v[i + 2]) else: 0'u32
    output[i] = uint8((30'u32 shr (left * 4 + center * 2 + right)) and 1)
  count
