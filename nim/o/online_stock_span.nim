const MaxDays = 4095

proc online_stock_span*(input: ptr UncheckedArray[int64], length: csize_t,
                        output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "online_stock_span".} =
  if input.isNil or length < 2 or input[0] < 1 or input[0] > MaxDays: return -1
  let count = int(input[0])
  if int(length) != count + 1: return -1
  for day in 0 ..< count:
    if input[day + 1] < 1 or input[day + 1] > 100000: return -1
  let outputBytes = csize_t(count * 8)
  if outputCapacity < outputBytes or output.isNil: return -2

  var decreasing: array[MaxDays, int]
  var top = 0
  for day in 0 ..< count:
    let price = input[day + 1]
    while top > 0 and input[decreasing[top - 1] + 1] <= price: dec top
    let span = if top == 0: day + 1 else: day - decreasing[top - 1]
    let encoded = uint64(span)
    for byte in 0 ..< 8:
      output[day * 8 + byte] = uint8((encoded shr (byte * 8)) and 255)
    decreasing[top] = day
    inc top
  int64(count)
