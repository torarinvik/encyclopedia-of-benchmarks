## Buy the largest affordable prefix after sorting the prices.
proc maximum_ice_cream_bars*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "maximum_ice_cream_bars".} =
  if length < 1 or length > 257 or input.isNil: return -1
  let coins = input[0]
  let count = int(length - 1)
  if coins < 0 or coins > 1_000_000: return -1
  var costs: array[256, int64]
  for index in 0 ..< count:
    let cost = input[index + 1]
    if cost < 1 or cost > 10_000: return -1
    var position = index
    while position > 0 and costs[position - 1] > cost:
      costs[position] = costs[position - 1]
      dec position
    costs[position] = cost
  var remaining = coins
  var bought = 0'i64
  for index in 0 ..< count:
    if costs[index] > remaining: break
    remaining -= costs[index]
    inc bought
  bought
