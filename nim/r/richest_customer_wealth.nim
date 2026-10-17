const
  MaxRows = 32
  MaxColumns = 32
  MaxInputLength = 2 + MaxRows * MaxColumns + 1
  MaxAmount = 1_000_000'i64

proc richest_customer_wealth*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "richest_customer_wealth".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  if input[0] < 1 or input[0] > MaxRows or input[1] < 1 or input[1] > MaxColumns: return -1
  let rows = int(input[0])
  let columns = int(input[1])
  if length != csize_t(2 + rows * columns): return -1
  var richest = 0'i64
  for row in 0 ..< rows:
    var wealth = 0'i64
    for column in 0 ..< columns:
      let amount = input[2 + row * columns + column]
      if amount < 0 or amount > MaxAmount: return -1
      wealth += amount
    if wealth > richest: richest = wealth
  richest
