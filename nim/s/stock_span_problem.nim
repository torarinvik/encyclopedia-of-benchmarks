proc stock_span_problem*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "stock_span_problem".} =
  if input == nil or length < 2 or length > 66: return -1
  let countValue = input[0]
  if countValue < 1 or countValue > 64: return -1
  let count = int(countValue)
  if length != csize_t(count + 1): return -1
  for day in 0 ..< count:
    let price = input[day + 1]
    if price < -2_147_483_648'i64 or price > 2_147_483_647'i64: return -1

  let outputBytes = count * 8
  if output == nil or capacity < csize_t(outputBytes): return -2
  var decreasing: array[64, int]
  var top = 0
  for day in 0 ..< count:
    let price = input[day + 1]
    while top > 0 and input[decreasing[top - 1] + 1] <= price: dec top
    let span = if top == 0: day + 1 else: day - decreasing[top - 1]
    var encoded = uint64(span)
    for byte in 0 ..< 8:
      output[day * 8 + byte] = uint8(encoded and 255)
      encoded = encoded shr 8
    decreasing[top] = day
    inc top
  int64(count)
