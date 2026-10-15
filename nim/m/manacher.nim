## Return the leftmost longest ASCII alphanumeric palindrome with Manacher's algorithm.
proc isAsciiAlphanumeric(value: int64): bool =
  (value >= ord('0').int64 and value <= ord('9').int64) or
  (value >= ord('A').int64 and value <= ord('Z').int64) or
  (value >= ord('a').int64 and value <= ord('z').int64)

proc transformedEqual(values: ptr UncheckedArray[int64], left, right: int): bool =
  if (left mod 2) != (right mod 2): return false
  if (left mod 2) == 0: return true
  values[left div 2] == values[right div 2]

proc manacher*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "manacher".} =
  if length == 0 or length > 1000 or values == nil: return -1
  let n = int(length)
  for index in 0 ..< n:
    if not isAsciiAlphanumeric(values[index]): return -1

  var radii: array[2001, int]
  let transformedLength = 2 * n + 1
  var center = 0
  var right = 0
  var bestCenter = 0
  var bestRadius = 0
  for index in 0 ..< transformedLength:
    var radius = 0
    if index < right:
      let mirror = 2 * center - index
      radius = min(radii[mirror], right - index)
    while radius < index and radius < transformedLength - 1 - index and
        transformedEqual(values, index - radius - 1, index + radius + 1):
      inc radius
    radii[index] = radius
    if index + radius > right:
      center = index
      right = index + radius
    if radius > bestRadius:
      bestCenter = index
      bestRadius = radius

  let bestStart = (bestCenter - bestRadius) div 2
  if outputCapacity < csize_t(bestRadius) or output == nil: return -2
  for index in 0 ..< bestRadius:
    output[index] = uint8(values[bestStart + index])
  int64(bestRadius)
