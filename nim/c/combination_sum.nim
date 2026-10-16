const MaxCandidates = 8
const MaxTarget = 20
const MaxPackedWords = 4096

proc enumerate(candidates: ptr UncheckedArray[int64], count, start: int,
    remaining: int64, depth: int, path: var array[MaxTarget, int64],
    packed: var array[MaxPackedWords, int64], used: var int) =
  if remaining == 0:
    packed[used] = int64(depth)
    inc used
    for i in 0 ..< depth:
      packed[used] = path[i]
      inc used
    inc packed[0]
    return
  for i in start ..< count:
    let candidate = candidates[i]
    if candidate > remaining: break
    path[depth] = candidate
    enumerate(candidates, count, i, remaining - candidate, depth + 1, path, packed, used)

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255'u64)

proc combination_sum*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "combination_sum".} =
  if input == nil or length < 3: return -1
  let countValue = input[0]
  let target = input[1]
  if countValue < 1 or countValue > MaxCandidates or target < 0 or target > MaxTarget: return -1
  let count = int(countValue)
  if length != csize_t(count + 2): return -1
  for i in 0 ..< count:
    let candidate = input[i + 2]
    if candidate < 1 or candidate > 24 or (i > 0 and input[i + 1] >= candidate): return -1

  var path: array[MaxTarget, int64]
  var packed: array[MaxPackedWords, int64]
  var used = 1
  packed[0] = 0
  enumerate(cast[ptr UncheckedArray[int64]](addr input[2]), count, 0,
            target, 0, path, packed, used)
  let required = used * 8
  if output == nil or capacity < csize_t(required): return -2
  for i in 0 ..< used: putI64(output, i * 8, packed[i])
  int64(required)
