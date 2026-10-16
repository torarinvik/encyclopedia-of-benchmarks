const MAX_ITEMS = 14
const MAX_PRICE = 1_000_000'i64

proc solve(prices: ptr UncheckedArray[int64], count, first, last: int): int64 =
  let year = int64(count - (last - first + 1) + 1)
  if first == last:
    return prices[first] * year
  let sellFirst = prices[first] * year + solve(prices, count, first + 1, last)
  let sellLast = prices[last] * year + solve(prices, count, first, last - 1)
  if sellFirst > sellLast: sellFirst else: sellLast

proc wine_problem_recursive*(prices: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "wine_problem_recursive".} =
  if prices == nil or length == 0 or length > csize_t(MAX_ITEMS): return -1
  for index in 0 ..< int(length):
    if prices[index] < 0 or prices[index] > MAX_PRICE: return -1
  solve(prices, int(length), 0, int(length) - 1)
