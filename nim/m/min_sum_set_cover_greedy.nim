const MaxN = 12
const MaxM = 16
const MaxInput = 18

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc min_sum_set_cover_greedy*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "min_sum_set_cover_greedy".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > int64(MaxN) or m64 < 1 or m64 > int64(MaxM) or int64(length) != 2 + m64: return -1
  let n = int(n64)
  let m = int(m64)
  var masks: array[MaxM, uint64]
  for set in 0..<m:
    let raw = input[2 + set]
    if raw <= 0 or uint64(raw) >= (1'u64 shl n): return -1
    masks[set] = uint64(raw)
  let outputBytes = 8 * (n + 1)
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var covered: array[MaxM, bool]
  var used: array[MaxN, bool]
  var order: array[MaxN, int64]
  var totalTime = 0'i64
  for slot in 1..n:
    var chosen = 0
    var bestCount = -1
    for element in 0..<n:
      if used[element]: continue
      var count = 0
      for set in 0..<m:
        if not covered[set] and (masks[set] and (1'u64 shl element)) != 0: inc count
      if count > bestCount:
        bestCount = count
        chosen = element
    used[chosen] = true
    order[slot - 1] = int64(chosen)
    for set in 0..<m:
      if not covered[set] and (masks[set] and (1'u64 shl chosen)) != 0:
        covered[set] = true
        totalTime += int64(slot)
  storeI64LE(output, 0, totalTime)
  for i in 0..<n: storeI64LE(output, 8 * (i + 1), order[i])
  int64(outputBytes)
