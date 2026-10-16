proc put_i64_le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc uniform_crossover*(input: ptr UncheckedArray[int64], length: csize_t,
                        output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "uniform_crossover".} =
  if input == nil or length < 4 or length > 193: return -1
  let n = input[0]
  if n < 1 or n > 64 or length != csize_t(1 + 3 * n): return -1
  for i in 0 ..< int(n):
    if input[1 + i] != 0 and input[1 + i] != 1: return -1
  for i in 0 ..< int(2 * n):
    let gene = input[1 + int(n) + i]
    if gene < -2147483648'i64 or gene > 2147483647'i64: return -1
  let count = int(n)
  let bytes = 16 * count
  if output == nil or capacity < csize_t(bytes): return -2
  for i in 0 ..< count:
    let alpha = input[1 + i]
    let parent_one = input[1 + count + i]
    let parent_two = input[1 + 2 * count + i]
    let child_one = if alpha == 1: parent_one else: parent_two
    let child_two = if alpha == 1: parent_two else: parent_one
    put_i64_le(output, i * 8, child_one)
    put_i64_le(output, (count + i) * 8, child_two)
  int64(bytes)
