const MaxTarget = 500
const Coins = [1'i64, 2, 5, 10, 20, 50, 100, 200]

proc problem31*(target: int64): int64 {.cdecl, exportc: "problem31".} =
  if target < 0 or target > MaxTarget.int64: return -1
  var ways: array[MaxTarget + 1, int64]
  ways[0] = 1
  for coin in Coins:
    var amount = coin
    while amount <= target:
      ways[amount.int] += ways[(amount - coin).int]
      amount += 1
  ways[target.int]
