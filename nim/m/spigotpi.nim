## Generate leading decimal digits with the pinned spigot recurrence.
const MaxDigits = 256
const MaxBoxes = 854

proc spigotpi*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "spigotpi".} =
  if length != 1 or input == nil or input[0] < 0 or input[0] > MaxDigits.int64: return -1
  let digitCount = int(input[0])
  if output == nil or outputCapacity < csize_t(digitCount): return -2
  if digitCount == 0: return 0

  let boxes = digitCount * 10 div 3
  var remainders: array[MaxBoxes, int64]
  for item in 0 ..< boxes: remainders[item] = 2
  var digitsHeld = 0
  for index in 0 ..< digitCount:
    var carriedOver = 0'i64
    var sum = 0'i64
    var cursor = boxes
    while cursor > 0:
      dec cursor
      let j = cursor
      remainders[j] *= 10
      sum = remainders[j] + carriedOver
      let denominator = int64(j * 2 + 1)
      let quotient = sum div denominator
      remainders[j] = sum mod denominator
      carriedOver = quotient * int64(j)
    remainders[0] = sum mod 10
    var q = sum div 10
    if q == 9:
      inc digitsHeld
    elif q == 10:
      q = 0
      var offset = 1
      while offset <= digitsHeld:
        let position = index - offset
        if output[position] == uint8(ord('9')): output[position] = uint8(ord('0'))
        else: inc output[position]
        inc offset
      digitsHeld = 1
    else:
      digitsHeld = 1
    output[index] = uint8(ord('0').int64 + q)
  int64(digitCount)
