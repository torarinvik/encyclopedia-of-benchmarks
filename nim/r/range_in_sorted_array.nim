type I64Array = ptr UncheckedArray[int64]
type ByteArray = ptr UncheckedArray[uint8]

proc findBound(values: I64Array, base, n: int, key: int64, findLeft: bool): int32 =
  var left = 0
  var right = n - 1
  while left <= right:
    let mid = left + (right - left) div 2
    if values[base + mid] > key: right = mid - 1
    elif values[base + mid] < key: left = mid + 1
    elif findLeft:
      if mid == 0 or values[base + mid - 1] != key: return int32(mid)
      right = mid - 1
    else:
      if mid == n - 1 or values[base + mid + 1] != key: return int32(mid)
      left = mid + 1
  -1

proc putI32Le(output: ByteArray, offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc range_in_sorted_array*(input: I64Array, length: csize_t, output: ByteArray, outputCapacity: csize_t): int64
    {.cdecl, exportc: "range_in_sorted_array".} =
  if input.isNil or length < 2 or input[0] < 0 or input[0] > 512 or length != csize_t(input[0] + 2): return -1
  let n = int(input[0])
  let key = input[n + 1]
  if key < -2_147_483_648'i64 or key > 2_147_483_647'i64: return -1
  for i in 0 ..< n:
    if input[i + 1] < -2_147_483_648'i64 or input[i + 1] > 2_147_483_647'i64: return -1
    if i > 0 and input[i] > input[i + 1]: return -1
  let first = findBound(input, 1, n, key, true)
  let last = findBound(input, 1, n, key, false)
  if output.isNil or outputCapacity < 8: return -2
  putI32Le(output, 0, first)
  putI32Le(output, 4, last)
  8
