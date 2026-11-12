const
  MaxOperations = 64
  MaxInsertions = 16
  MaxInputValues = 1 + 2 * MaxOperations
  MaxOutputBytes = 8 * MaxOperations
  BitCount = 63

proc insertValue(basis: var array[BitCount, uint64], value: uint64) =
  var reduced = value
  for bit in countdown(BitCount - 1, 0):
    if reduced == 0: break
    if ((reduced shr bit) and 1'u64) == 0: continue
    if basis[bit] == 0:
      basis[bit] = reduced
      return
    reduced = reduced xor basis[bit]

proc maximumValue(basis: array[BitCount, uint64]): uint64 =
  var best = 0'u64
  for bit in countdown(BitCount - 1, 0):
    let candidate = best xor basis[bit]
    if candidate > best: best = candidate
  best

proc containsValue(basis: array[BitCount, uint64], rawValue: uint64): bool =
  var value = rawValue
  for bit in countdown(BitCount - 1, 0):
    if ((value shr bit) and 1'u64) == 0: continue
    if basis[bit] == 0: return false
    value = value xor basis[bit]
  value == 0

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc xor_linear_basis*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "xor_linear_basis".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputValues): return -1
  let qValue = input[0]
  if qValue < 1 or qValue > MaxOperations: return -1
  let q = int(qValue)

  var basis: array[BitCount, uint64]
  var results: array[MaxOperations, int64]
  var resultCount = 0
  var cursor = 1
  var insertionCount = 0
  for _ in 0 ..< q:
    if cursor >= int(length): return -1
    let kind = input[cursor]
    inc cursor
    if kind == 0 or kind == 2:
      if cursor >= int(length): return -1
      let rawValue = input[cursor]
      inc cursor
      if rawValue < 0: return -1
      let value = uint64(rawValue)
      if kind == 0:
        inc insertionCount
        if insertionCount > MaxInsertions: return -1
        insertValue(basis, value)
      else:
        results[resultCount] = if containsValue(basis, value): 1 else: 0
        inc resultCount
    elif kind == 1:
      results[resultCount] = int64(maximumValue(basis))
      inc resultCount
    else:
      return -1
  if cursor != int(length): return -1

  let outputBytes = resultCount * 8
  if outputBytes == 0: return 0
  if output.isNil or int(capacity) < outputBytes: return -2
  for result in 0 ..< resultCount:
    storeLe(output, result * 8, results[result])
  int64(outputBytes)
