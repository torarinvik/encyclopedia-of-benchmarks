const MaxN = 4
const MaxInput = 2
const MaxWords = 97

proc visit(permutation: var array[MaxN, int64], n: int,
    staged: var array[MaxWords, int64], cursor: var int) =
  for index in 0 ..< n:
    staged[cursor] = permutation[index]
    inc cursor
  var reversePoint = n
  for index in 0 ..< n - 1:
    if permutation[index] > permutation[index + 1]:
      reversePoint = index + 1
      break
  for child in 1 ..< reversePoint:
    swap(permutation[child - 1], permutation[child])
    visit(permutation, n, staged, cursor)
    swap(permutation[child - 1], permutation[child])
  if reversePoint + 2 <= n and permutation[reversePoint - 1] < permutation[reversePoint + 1]:
    swap(permutation[reversePoint], permutation[reversePoint + 1])
    visit(permutation, n, staged, cursor)
    swap(permutation[reversePoint], permutation[reversePoint + 1])

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc reverse_search_permutation_enumeration*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "reverse_search_permutation_enumeration".} =
  if input == nil or length < 1 or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  if length != 1 or nValue < 1 or nValue > MaxN: return -1
  let n = int(nValue)
  var count = 1
  for factor in 2 .. n: count *= factor
  let words = 1 + n * count
  let required = words * 8
  if output == nil or capacity < csize_t(required): return -2

  var permutation: array[MaxN, int64]
  var staged: array[MaxWords, int64]
  for index in 0 ..< n: permutation[index] = int64(index + 1)
  staged[0] = int64(count)
  var cursor = 1
  visit(permutation, n, staged, cursor)
  for word in 0 ..< words: storeI64Le(output, word * 8, staged[word])
  int64(required)
