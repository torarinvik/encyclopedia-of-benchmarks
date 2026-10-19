const SortElements = 5000
const MaxPrefixCount = 100'i64
const MaxOutputBytes = 700

proc sourceQuicksort(values: var array[SortElements + 1, int64], left, right: int64) =
  var i = left
  var j = right
  let pivot = values[int((left + right) div 2)]
  while true:
    while values[int(i)] < pivot: inc i
    while pivot < values[int(j)]: dec j
    if i <= j:
      swap(values[int(i)], values[int(j)])
      inc i
      dec j
    if i > j: break
  if left < j: sourceQuicksort(values, left, j)
  if i < right: sourceQuicksort(values, i, right)

proc appendNumber(buffer: var array[MaxOutputBytes, uint8], used: var int, value: int64) =
  var reversed: array[20, uint8]
  var remaining = value
  var count = 0
  if remaining < 0:
    buffer[used] = uint8(ord('-'))
    inc used
    remaining = -remaining
  while true:
    reversed[count] = uint8(48'i64 + remaining mod 10)
    inc count
    remaining = remaining div 10
    if remaining == 0: break
  while count > 0:
    dec count
    buffer[used] = reversed[count]
    inc used
  buffer[used] = 10'u8
  inc used

proc stanford_quicksort*(prefixCount: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "stanford_quicksort".} =
  if prefixCount < 1 or prefixCount > MaxPrefixCount: return -1
  if output.isNil: return -2

  var staged: array[MaxOutputBytes, uint8]
  var used = 0
  for run in 0 ..< int(prefixCount):
    var values: array[SortElements + 1, int64]
    var state = 74755'i64
    for index in 1 .. SortElements:
      state = (state * 1309'i64 + 13849'i64) and 65535'i64
      values[index] = state - 50000
    sourceQuicksort(values, 1, SortElements)
    appendNumber(staged, used, values[run + 1])

  if outputCapacity < csize_t(used): return -2
  for index in 0 ..< used: output[index] = staged[index]
  int64(used)
