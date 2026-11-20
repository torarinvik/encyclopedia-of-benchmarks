type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc gcdI64(left, right: int64): int64 =
  var a = left
  var b = right
  while b != 0:
    let remainder = a mod b
    a = b
    b = remainder
  a

proc ekg_sequence*(input: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "ekg_sequence".} =
  const MaxN = 8'i64
  const MaxTerms = 8
  const MaxCandidate = 40320
  const MaxParseableLength = 2
  if input == nil or length < 1 or length > MaxParseableLength: return -1
  let requested = input[0]
  if length != 1 or requested < 1 or requested > MaxN: return -1

  var terms: array[MaxTerms, int64]
  var used: array[MaxCandidate + 1, uint8]
  terms[0] = 1
  used[1] = 1
  var termCount = 1
  if requested >= 2:
    terms[1] = 2
    used[2] = 1
    termCount = 2

  while termCount < int(requested):
    let position = int64(termCount + 1)
    let previous = terms[termCount - 1]
    let searchBound = previous * position
    var candidate = 1'i64
    while candidate <= searchBound:
      if used[int(candidate)] == 0 and gcdI64(previous, candidate) > 1:
        break
      inc candidate
    if candidate > searchBound: return -1
    terms[termCount] = candidate
    used[int(candidate)] = 1
    inc termCount

  let outputBytes = int(requested) * 8
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  for index in 0 ..< termCount:
    let bits = uint64(terms[index])
    for byte in 0 ..< 8:
      output[index * 8 + byte] = uint8((bits shr (byte * 8)) and 255'u64)
  int64(outputBytes)
