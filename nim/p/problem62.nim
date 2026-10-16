## Group cubes by their sorted decimal digits and return the first cube in the target group.
const
  TableSize = 16_384
  MaxBase = 8_384
  SignatureLengthFactor = 4_503_599_627_370_496'i64

proc digitSignature(cube: int64): int64 =
  var counts: array[10, int]
  var length = 0
  var remaining = cube
  while remaining > 0:
    inc counts[int(remaining mod 10)]
    inc length
    remaining = remaining div 10
  if length == 0:
    counts[0] = 1
    length = 1
  var sortedDigits = 0'i64
  for digit in 0 ..< 10:
    for _ in 0 ..< counts[digit]:
      sortedDigits = sortedDigits * 16 + int64(digit)
  int64(length) * SignatureLengthFactor + sortedDigits

proc signatureSlot(key: int64): int =
  let size = int64(TableSize)
  int((key mod size + (key div size mod size) * 31 +
       (key div (size * size) mod size) * 17 +
       (key div (size * size * size) mod size) * 7) mod size)

proc problem62*(targetCount: int64): int64 {.cdecl, exportc: "problem62".} =
  if targetCount < 1 or targetCount > 5:
    return -1
  var keys: array[TableSize, int64]
  var firstCubes: array[TableSize, int64]
  var counts: array[TableSize, int]
  for base in 0 .. MaxBase:
    let cube = int64(base) * int64(base) * int64(base)
    let key = digitSignature(cube)
    var slot = signatureSlot(key)
    while keys[slot] != 0 and keys[slot] != key:
      slot = (slot + 1) mod TableSize
    if keys[slot] == 0:
      keys[slot] = key
      firstCubes[slot] = cube
    inc counts[slot]
    if int64(counts[slot]) == targetCount:
      return firstCubes[slot]
  -1
