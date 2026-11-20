const MaxBits = 4096
const MaxWords = 64
const MaxOperations = 64

proc popcount64(value: uint64): int32 =
  var remaining = value
  while remaining != 0:
    remaining = remaining and (remaining - 1)
    inc result

proc storeI32Le(output: ptr UncheckedArray[uint8], pos: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4:
    output[pos + byte] = uint8((bits shr (8 * byte)) and 255)

proc bitset_xor_shift_trace*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "bitset_xor_shift_trace".} =
  if input.isNil or length < 3 or length > 131: return -1
  let n64 = input[0]
  let q64 = input[1]
  if n64 < 1 or n64 > MaxBits or q64 < 0 or q64 > MaxOperations: return -1
  let n = int(n64)
  let q = int(q64)
  let wordCount = (n + 63) div 64
  let shiftOffset = 2 + wordCount
  if int64(length) != int64(shiftOffset + q): return -1

  var words: array[MaxWords, uint64]
  for word in 0 ..< wordCount: words[word] = cast[uint64](input[2 + word])
  let tailBits = n mod 64
  let tailMask = if tailBits == 0: high(uint64) else: (1'u64 shl tailBits) - 1
  if (words[wordCount - 1] and not tailMask) != 0: return -1
  for operation in 0 ..< q:
    let shift = input[shiftOffset + operation]
    if shift < -(n64 - 1) or shift > n64 - 1: return -1

  let outputBytes = q * 4
  if outputBytes > 0 and (output.isNil or capacity < csize_t(outputBytes)): return -2
  var counts: array[MaxOperations, int32]
  for operation in 0 ..< q:
    let shift = input[shiftOffset + operation]
    if shift == 0:
      for word in 0 ..< wordCount: words[word] = 0
    elif shift > 0:
      let distance = int(shift)
      let whole = distance div 64
      let part = distance mod 64
      for destination in 0 ..< wordCount:
        let source = destination + whole
        var shifted = if source < wordCount: words[source] shr part else: 0'u64
        if part != 0 and source + 1 < wordCount:
          shifted = shifted or (words[source + 1] shl (64 - part))
        words[destination] = words[destination] xor shifted
    else:
      let distance = int(-shift)
      let whole = distance div 64
      let part = distance mod 64
      for reverseIndex in 0 ..< wordCount:
        let destination = wordCount - 1 - reverseIndex
        let source = destination - whole
        var shifted = 0'u64
        if source >= 0: shifted = words[source] shl part
        if part != 0 and source > 0: shifted = shifted or (words[source - 1] shr (64 - part))
        words[destination] = words[destination] xor shifted
    words[wordCount - 1] = words[wordCount - 1] and tailMask
    for word in 0 ..< wordCount: counts[operation] += popcount64(words[word])
  for operation in 0 ..< q: storeI32Le(output, operation * 4, counts[operation])
  int64(outputBytes)
