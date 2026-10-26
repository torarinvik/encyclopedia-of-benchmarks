const MaxN = 32
const MaxInput = 33
const Capacity = 10000'i64

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc harmonic_4_bin_packing*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "harmonic_4_bin_packing".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  if n64 < 1 or n64 > int64(MaxN) or int64(length) != 1 + n64: return -1
  let n = int(n64)
  for i in 0..<n:
    if input[1 + i] < 1 or input[1 + i] > Capacity: return -1
  let outputBytes = 8 * (n + 1)
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var current: array[4, int64] = [-1'i64, -1, -1, -1]
  var remaining: array[4, int64]
  var assignment: array[MaxN, int64]
  var bins = 0'i64
  for i in 0..<n:
    let size = input[1 + i]
    let kind = if size * 2 > Capacity: 0 elif size * 3 > Capacity: 1 elif size * 4 > Capacity: 2 else: 3
    if current[kind] < 0 or size > remaining[kind]:
      current[kind] = bins
      inc bins
      remaining[kind] = Capacity
    assignment[i] = current[kind]
    remaining[kind] -= size
  storeI64LE(output, 0, bins)
  for i in 0..<n: storeI64LE(output, 8 * (i + 1), assignment[i])
  int64(outputBytes)
