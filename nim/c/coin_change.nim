## Return the minimum number of unlimited coins needed to reach an amount.
proc coin_change*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "coin_change".} =
  if packed.isNil or length < 2 or length > 130: return -1
  let amount = packed[0]
  let coinCount = packed[1]
  if amount < 0 or amount > 512 or coinCount < 0 or coinCount > 128: return -1
  if length != csize_t(2 + coinCount): return -1
  for coinIndex in 0 ..< int(coinCount):
    if packed[2 + coinIndex] < 1 or packed[2 + coinIndex] > 4096: return -1

  var minimum: array[513, int64]
  var current = 1
  while current <= int(amount):
    var best = 513'i64
    for coinIndex in 0 ..< int(coinCount):
      let coin = int(packed[2 + coinIndex])
      if coin <= current and minimum[current - coin] < 513:
        best = min(best, minimum[current - coin] + 1)
    minimum[current] = best
    inc current
  if minimum[int(amount)] < 513: minimum[int(amount)] else: -1
