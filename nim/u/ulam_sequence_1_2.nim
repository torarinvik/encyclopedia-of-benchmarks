const
  MaxN = 14'i64
  MaxCandidate = 64'i64
  MaxParseableLength = 2

proc ulam_sequence_1_2*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "ulam_sequence_1_2".} =
  if input.isNil or length < 1 or length > csize_t(MaxParseableLength): return -1
  let requested = input[0]
  if length != 1 or requested < 1 or requested > MaxN: return -1

  var terms: array[14, int64]
  var representations: array[75, int64]
  terms[0] = 1
  terms[1] = 2
  representations[3] = 1
  var termCount = 2

  while termCount < int(requested):
    var candidate = terms[termCount - 1] + 1
    while candidate <= MaxCandidate and representations[int(candidate)] != 1:
      inc candidate
    if candidate > MaxCandidate: return -1
    for old in 0 ..< termCount:
      let sum = int(candidate + terms[old])
      if representations[sum] < 2: inc representations[sum]
    terms[termCount] = candidate
    inc termCount
  terms[int(requested) - 1]
