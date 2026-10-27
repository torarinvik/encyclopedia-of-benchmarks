proc putU64(output: ptr UncheckedArray[uint8], word: int, value: uint64) =
  for b in 0 ..< 8: output[word * 8 + b] = uint8((value shr (8 * b)) and 255)

proc psi_suffix_array_access*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "psi_suffix_array_access".} =
  if input.isNil or length < 5 or length > 67: return -1
  let n0 = input[0]; let query0 = input[1]; let stride0 = input[2]
  if n0 < 1 or n0 > 32 or query0 < 0 or query0 >= n0 or stride0 < 1 or stride0 > n0 or int(length) != 3 + 2 * int(n0): return -1
  let n = int(n0); let query = int(query0); let stride = int(stride0)
  var destinations: array[32, bool]
  var visited: array[32, bool]
  for i in 0 ..< n:
    let next = input[3 + i]; let sample = input[3 + n + i]
    if next < 0 or next >= n0 or destinations[int(next)] or sample < 0 or sample > n0: return -1
    destinations[int(next)] = true
  var anchor = -1
  for i in 0 ..< n:
    if input[3 + n + i] != 0:
      anchor = i
      break
  if anchor < 0: return -1
  let anchorValue = input[3 + n + anchor]
  if (anchorValue - 1) mod stride0 != 0: return -1
  var fullSa: array[32, uint64]
  var rank = anchor
  var value = anchorValue
  for _ in 0 ..< n:
    if visited[rank]: return -1
    visited[rank] = true
    fullSa[rank] = uint64(value)
    rank = int(input[3 + rank])
    value = if value == n0: 1 else: value + 1
  if rank != anchor or value != anchorValue: return -1
  for i in 0 ..< n:
    let expected = if (fullSa[i] - 1'u64) mod uint64(stride) == 0'u64: int64(fullSa[i]) else: 0'i64
    if input[3 + n + i] != expected: return -1
  rank = query
  var hops = 0
  while input[3 + n + rank] == 0:
    rank = int(input[3 + rank])
    inc hops
    if hops >= stride: return -1
  var position0 = input[3 + n + rank] - 1 - int64(hops)
  position0 = position0 mod n0
  if position0 < 0: position0 += n0
  if output.isNil or int(capacity) < 16: return -2
  putU64(output, 0, uint64(position0 + 1))
  putU64(output, 1, uint64(hops))
  16
