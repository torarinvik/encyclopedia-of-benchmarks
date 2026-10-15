const MaxLevel = 6
const MaxIntervals = 64
const Scale = 1_000_000'u64

proc putByte(output: ptr UncheckedArray[uint8], capacity: csize_t,
             outputLength: var int, value: uint8): bool =
  if csize_t(outputLength) >= capacity: return false
  output[outputLength] = value
  inc outputLength
  true

proc putText(output: ptr UncheckedArray[uint8], capacity: csize_t,
             outputLength: var int, text: string): bool =
  for character in text:
    if not putByte(output, capacity, outputLength, uint8(ord(character))): return false
  true

proc putUint(output: ptr UncheckedArray[uint8], capacity: csize_t,
             outputLength: var int, value: uint64): bool =
  var digits: array[20, uint8]
  var count = 0
  var remaining = value
  while true:
    digits[count] = uint8(ord('0') + int(remaining mod 10))
    inc count
    remaining = remaining div 10
    if remaining == 0: break
  while count > 0:
    dec count
    if not putByte(output, capacity, outputLength, digits[count]): return false
  true

proc putFixed(output: ptr UncheckedArray[uint8], capacity: csize_t,
              outputLength: var int, ticks: uint64): bool =
  if not putUint(output, capacity, outputLength, ticks div Scale) or
     not putByte(output, capacity, outputLength, uint8(ord('.'))): return false
  var fraction = ticks mod Scale
  var divisor = 100_000'u64
  while divisor > 0:
    let digit = uint8(ord('0') + int((fraction div divisor) mod 10))
    if not putByte(output, capacity, outputLength, digit): return false
    fraction = fraction mod divisor
    divisor = divisor div 10
  true

proc cantor_set*(input: ptr UncheckedArray[int64], length: csize_t,
                 output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "cantor_set".} =
  if input.isNil or length != csize_t(3): return -1
  if input[0] < 0 or input[0] > input[1] or input[1] > 100_000 or
     input[2] < 0 or input[2] > MaxLevel: return -1
  if output.isNil: return -2

  let start = uint64(input[0])
  let span = uint64(input[1] - input[0])
  let levels = int(input[2])
  var positions: array[MaxIntervals, uint64]
  var next: array[MaxIntervals, uint64]
  var intervalCount = 1
  var denominator = 1'u64
  var outputLength = 0

  for level in 0 .. levels:
    if not putText(output, outputCapacity, outputLength, "Level ") or
       not putUint(output, outputCapacity, outputLength, uint64(level)) or
       not putByte(output, outputCapacity, outputLength, 9'u8): return -2
    for index in 0 ..< intervalCount:
      let leftNumerator = start * denominator + span * positions[index]
      let rightNumerator = start * denominator + span * (positions[index] + 1)
      let left = (leftNumerator * Scale + denominator div 2) div denominator
      let right = (rightNumerator * Scale + denominator div 2) div denominator
      if not putText(output, outputCapacity, outputLength, "\t[") or
         not putFixed(output, outputCapacity, outputLength, left) or
         not putText(output, outputCapacity, outputLength, "] -- [") or
         not putFixed(output, outputCapacity, outputLength, right) or
         not putByte(output, outputCapacity, outputLength, uint8(ord(']'))): return -2
    if not putByte(output, outputCapacity, outputLength, 10'u8): return -2
    if level < levels:
      if not putByte(output, outputCapacity, outputLength, 10'u8): return -2
      for index in 0 ..< intervalCount:
        next[2 * index] = positions[index] * 3
        next[2 * index + 1] = positions[index] * 3 + 2
      intervalCount *= 2
      for index in 0 ..< intervalCount:
        positions[index] = next[index]
      denominator *= 3

  if csize_t(outputLength) >= outputCapacity: return -2
  output[outputLength] = 0
  inc outputLength
  int64(outputLength)
