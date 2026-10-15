const MaxLength = 256

type
  I64Input = ptr UncheckedArray[int64]
  ByteOutput = ptr UncheckedArray[uint8]

proc palindrome_partitioning*(input: I64Input, length: csize_t, output: ByteOutput,
    outputCapacity: csize_t): int64
    {.cdecl, exportc: "palindrome_partitioning".} =
  if input.isNil or length == 0 or length > csize_t(MaxLength): return -1
  let n = int(length)
  for index in 0 ..< n:
    if input[index] < 0 or input[index] > 127: return -1
  if output.isNil or outputCapacity < 8: return -2

  var palindrome: array[MaxLength * MaxLength, bool]
  var cuts: array[MaxLength, int64]
  for index in 0 ..< MaxLength * MaxLength: palindrome[index] = false
  for endIndex in 0 ..< n:
    var best = int64(endIndex)
    for start in 0 .. endIndex:
      if input[start] == input[endIndex] and
          (endIndex - start < 2 or palindrome[(start + 1) * MaxLength + endIndex - 1]):
        palindrome[start * MaxLength + endIndex] = true
        let candidate = if start == 0: 0'i64 else: cuts[start - 1] + 1
        if candidate < best: best = candidate
    cuts[endIndex] = best

  let bits = cast[uint64](cuts[n - 1])
  for byte in 0 ..< 8:
    output[byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)
  1
