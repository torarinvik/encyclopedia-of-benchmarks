const MaxAmount = 30
const MaxCoins = 8

## Count source-compatible coin-type combinations for amount minus one.
proc coinchange*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "coinchange".} =
  if values.isNil or length < 2 or length > MaxCoins + 2: return -1
  let amountValue = values[0]
  let coinCountValue = values[1]
  if amountValue < 1 or amountValue > MaxAmount or coinCountValue < 0 or coinCountValue > MaxCoins: return -1
  let amount = int(amountValue)
  let coinCount = int(coinCountValue)
  if int(length) != coinCount + 2: return -1
  for index in 0 ..< coinCount:
    if values[index + 2] < 1 or values[index + 2] > MaxAmount: return -1

  var combinations: array[MaxAmount, int64]
  combinations[0] = 1
  for coinIndex in 0 ..< coinCount:
    let coin = int(values[coinIndex + 2])
    for subtotal in coin ..< amount:
      combinations[subtotal] += combinations[subtotal - coin]
  combinations[amount - 1]
