proc three_way_partition*(input: ptr UncheckedArray[int64], length: csize_t,
                          output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "three_way_partition".} =
  if length < 2 or length > 258: return -1
  let n = input[0]; let pivot = input[1]
  if n < 0 or n > 256 or length != csize_t(n + 2) or pivot < int64(low(int32)) or pivot > int64(high(int32)): return -1
  var a: array[256, int32]
  for i in 0 ..< int(n):
    if input[i + 2] < int64(low(int32)) or input[i + 2] > int64(high(int32)): return -1
    a[i] = int32(input[i + 2])
  var lowIdx = 0; var mid = 0; var highIdx = int(n)
  while mid < highIdx:
    if int64(a[mid]) < pivot: swap(a[lowIdx], a[mid]); inc lowIdx; inc mid
    elif int64(a[mid]) > pivot: dec highIdx; swap(a[mid], a[highIdx])
    else: inc mid
  let bytes = csize_t((int(n) + 2) * 4)
  if capacity < bytes: return -2
  let out32 = cast[ptr UncheckedArray[int32]](output)
  for i in 0 ..< int(n): out32[i] = a[i]
  out32[int(n)] = int32(lowIdx); out32[int(n) + 1] = int32(highIdx)
  n + 2
