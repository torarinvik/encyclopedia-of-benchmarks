proc put_i64_le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc double_point_crossover*(input: ptr UncheckedArray[int64], length: csize_t,
                             output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "double_point_crossover".} =
  if input == nil or length < 7 or length > 131: return -1
  let n = input[0]
  let j1 = input[1]
  let j2 = input[2]
  if n < 2 or n > 64 or length != csize_t(3 + 2 * n) or j1 < 1 or j1 >= j2 or j2 > n: return -1
  for i in 0 ..< int(2 * n):
    if input[3 + i] < -2147483648'i64 or input[3 + i] > 2147483647'i64: return -1
  let count = int(n)
  let bytes = 16 * count
  if output == nil or capacity < csize_t(bytes): return -2
  for i in 0 ..< count:
    var child1 = input[3 + i]
    var child2 = input[3 + count + i]
    if i >= int(j1) and i < int(j2): swap(child1, child2)
    put_i64_le(output, i * 8, child1)
    put_i64_le(output, (count + i) * 8, child2)
  int64(bytes)
