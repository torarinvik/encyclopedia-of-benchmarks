const MAX_ITEMS = 64
const MAX_PRICE = 1_000_000'i64

proc solve(prices: ptr UncheckedArray[int64], count, first, last: int,
           memo: ptr UncheckedArray[int64]): int64 =
  let slot = first * MAX_ITEMS + last
  let year = int64(count - (last - first + 1) + 1)
  if first == last:
    memo[slot] = prices[first] * year
    return memo[slot]
  if memo[slot] != 0: return memo[slot]
  let sellFirst = prices[first] * year + solve(prices, count, first + 1, last, memo)
  let sellLast = prices[last] * year + solve(prices, count, first, last - 1, memo)
  memo[slot] = max(sellFirst, sellLast)
  memo[slot]

proc wine_problem_memoized*(prices: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "wine_problem_memoized".} =
  if prices == nil or length == 0 or length > csize_t(MAX_ITEMS): return -1
  for index in 0 ..< int(length):
    if prices[index] < 1 or prices[index] > MAX_PRICE: return -1
  var memo: array[MAX_ITEMS * MAX_ITEMS, int64]
  let memoPointer = cast[ptr UncheckedArray[int64]](addr memo[0])
  solve(prices, int(length), 0, int(length) - 1, memoPointer)
