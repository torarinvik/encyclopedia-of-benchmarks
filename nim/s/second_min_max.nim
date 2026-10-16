type I64Input = ptr UncheckedArray[int64]

const MaxInputLength = 259
const Int32MinValue = -2_147_483_648'i64
const Int32MaxValue = 2_147_483_647'i64

proc second_min_max*(input: I64Input, length: csize_t): int64
    {.cdecl, exportc: "second_min_max".} =
  const invalid = low(int64)
  if input == nil or length < 4 or length > csize_t(MaxInputLength): return invalid
  let operation = input[0]
  let rawCount = input[1]
  if (operation != 0 and operation != 1) or rawCount < 2 or rawCount > 256: return invalid
  let count = int(rawCount)
  if int(length) != count + 2: return invalid
  let initial = if operation == 0: Int32MaxValue else: Int32MinValue
  var best = initial
  var second = initial
  for index in 0 ..< count:
    let value = input[index + 2]
    if value < Int32MinValue or value > Int32MaxValue: return invalid
    let better = if operation == 0: value < best else: value > best
    if better:
      second = best
      best = value
    else:
      let improvesSecond = if operation == 0: value < second else: value > second
      if improvesSecond and value != best: second = value
  if second == initial: return invalid
  second
