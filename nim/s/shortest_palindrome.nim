const MaxInputLength = 64

proc shortest_palindrome*(input: ptr UncheckedArray[int64], length: csize_t,
                          output: ptr UncheckedArray[uint8],
                          outputCapacity: csize_t): int64
    {.cdecl, exportc: "shortest_palindrome".} =
  if length > MaxInputLength: return -1
  if length > 0 and input.isNil: return -1
  for i in 0 ..< int(length):
    if input[i] < 32 or input[i] > 126: return -1
  if length == 0: return 0

  var suffix: array[64, int]
  for i in 1 ..< int(length):
    var matched = suffix[i - 1]
    while matched > 0 and input[matched] != input[i]:
      matched = suffix[matched - 1]
    if input[matched] == input[i]: inc matched
    suffix[i] = matched

  var prefixMatch = 0
  for i in 0 ..< int(length):
    let reversedValue = input[int(length) - 1 - i]
    while prefixMatch > 0 and reversedValue != input[prefixMatch]:
      prefixMatch = suffix[prefixMatch - 1]
    if reversedValue == input[prefixMatch]: inc prefixMatch

  let outputLength = 2 * int(length) - prefixMatch
  if output.isNil or outputCapacity < csize_t(outputLength): return -2
  for i in 0 ..< int(length):
    output[i] = uint8(input[int(length) - 1 - i])
  for i in prefixMatch ..< int(length):
    output[int(length) + i - prefixMatch] = uint8(input[i])
  int64(outputLength)
