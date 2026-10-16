const MaxTarget = 200
const Coins = [1'i64, 2, 5, 10, 20, 50, 100, 200]

proc countWays(target: int64, coinIndex: int): int64 =
  if target < 0: return 0
  if coinIndex == 0: return 1
  let coin = Coins[coinIndex]
  countWays(target - coin, coinIndex) + countWays(target, coinIndex - 1)

proc problem31_recursive*(target: int64): int64 {.cdecl, exportc: "problem31_recursive".} =
  if target < 0 or target > MaxTarget.int64: return -1
  countWays(target, 7)
