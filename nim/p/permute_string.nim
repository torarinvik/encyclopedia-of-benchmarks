const
  MaxN = 7
  MaxInputLength = 9
  MaxOutputBytes = 35280

proc factorial(value: int): int =
  if value < 2: return 1
  result = 1
  for factor in 2 .. value: result *= factor

proc uniquePermutationCount(values: array[MaxN, uint8], length: int): int =
  if length == 0: return 0
  var frequencies: array[128, int]
  for index in 0 ..< length: inc frequencies[int(values[index])]
  result = factorial(length)
  for frequency in frequencies:
    result = result div factorial(frequency)

proc nextPermutation(values: var array[MaxN, uint8], length: int): bool =
  if length < 2: return false
  var pivot = length - 1
  while pivot > 0 and values[pivot - 1] >= values[pivot]: dec pivot
  if pivot == 0: return false
  var successor = length - 1
  while values[successor] <= values[pivot - 1]: dec successor
  swap(values[pivot - 1], values[successor])
  var left = pivot
  var right = length - 1
  while left < right:
    swap(values[left], values[right])
    inc left
    dec right
  true

proc putPermutation(output: ptr UncheckedArray[uint8], offset: int,
                    values: array[MaxN, uint8], length: int) =
  for column in 0 ..< length: output[offset + column] = values[column]

proc permute_string*(input: ptr UncheckedArray[int64], inputLength: csize_t,
                     output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "permute_string".} =
  if input == nil or inputLength < 1 or inputLength > csize_t(MaxInputLength): return -1
  if input[0] < 0 or input[0] > MaxN: return -1
  let characterCount = int(input[0])
  if int(inputLength) != characterCount + 1: return -1

  var values: array[MaxN, uint8]
  for index in 0 ..< characterCount:
    let value = input[index + 1]
    if value < 0 or value > 127: return -1
    values[index] = uint8(value)
  for index in 1 ..< characterCount:
    let value = values[index]
    var position = index
    while position > 0 and values[position - 1] > value:
      values[position] = values[position - 1]
      dec position
    values[position] = value

  let permutationCount = uniquePermutationCount(values, characterCount)
  let outputBytes = permutationCount * characterCount
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  for row in 0 ..< permutationCount:
    putPermutation(output, row * characterCount, values, characterCount)
    if row + 1 < permutationCount: discard nextPermutation(values, characterCount)
  int64(outputBytes)
