proc digitAtPosition(positionInput: int64): int64 =
  var position = positionInput
  var digits: int64 = 1
  var blockCount: int64 = 9
  var firstNumber: int64 = 1
  while position > digits * blockCount:
    position -= digits * blockCount
    inc digits
    blockCount *= 10
    firstNumber *= 10
  let number = firstNumber + (position - 1) div digits
  let offset = (position - 1) mod digits
  var divisor: int64 = 1
  for _ in 0 ..< digits - offset - 1: divisor *= 10
  (number div divisor) mod 10

proc problem40*(ignored: int64): int64 {.cdecl, exportc: "problem40".} =
  if ignored != 0: return -1
  var product = digitAtPosition(1)
  product *= digitAtPosition(10)
  product *= digitAtPosition(100)
  product *= digitAtPosition(1_000)
  product *= digitAtPosition(10_000)
  product *= digitAtPosition(100_000)
  product *= digitAtPosition(1_000_000)
  product
