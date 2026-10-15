const MaxDimension = 1000'i64
const InvalidResult = -1'i64

proc volume*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "volume".} =
  if input == nil or length != 4: return InvalidResult
  let operation = input[0]
  let a = input[1]
  let b = input[2]
  let c = input[3]
  if a < 0 or a > MaxDimension or b < 0 or b > MaxDimension or c < 0 or c > MaxDimension:
    return InvalidResult
  if operation == 0:
    if b != 0 or c != 0: return InvalidResult
    return a * a * a
  if operation == 1: return a * b * c
  if operation == 2:
    let product = a * b * c
    if product mod 2 != 0: return InvalidResult
    return product div 2
  if operation == 3:
    let product = a * b * c
    if product mod 3 != 0: return InvalidResult
    return product div 3
  InvalidResult
