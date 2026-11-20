const
  MaxN = 30'i64
  MaxParseableLength = 2

proc mian_chowla_sequence*(input: ptr UncheckedArray[int64],
                           length: csize_t): int64
    {.cdecl, exportc: "mian_chowla_sequence".} =
  if input.isNil or length < 1 or length > csize_t(MaxParseableLength): return -1
  let requested = input[0]
  if length != 1 or requested < 1 or requested > MaxN: return -1

  var terms: array[30, int64]
  var usedSums: array[465, int64]
  var termCount = 1
  var sumCount = 1
  terms[0] = 1
  usedSums[0] = 2

  while termCount < int(requested):
    var candidate = terms[termCount - 1] + 1
    while true:
      var valid = true
      for term in 0 ..< termCount:
        let sum = candidate + terms[term]
        for old in 0 ..< sumCount:
          if usedSums[old] == sum:
            valid = false
            break
        if not valid: break
      if valid:
        let doubled = 2 * candidate
        for old in 0 ..< sumCount:
          if usedSums[old] == doubled:
            valid = false
            break
      if valid: break
      inc candidate

    for term in 0 ..< termCount:
      usedSums[sumCount] = candidate + terms[term]
      inc sumCount
    usedSums[sumCount] = 2 * candidate
    inc sumCount
    terms[termCount] = candidate
    inc termCount
  terms[int(requested) - 1]
