const MAX_ITEMS = 64
const MAX_PRICE = 1_000_000'i64

proc wine_problem_tabulated*(prices: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "wine_problem_tabulated".} =
  if prices == nil or length == 0 or length > csize_t(MAX_ITEMS): return -1
  for index in 0 ..< int(length):
    if prices[index] < 0 or prices[index] > MAX_PRICE: return -1
  var table: array[MAX_ITEMS * MAX_ITEMS, int64]
  for width in 1 .. int(length):
    let year = int64(int(length) - width + 1)
    for first in 0 .. int(length) - width:
      let last = first + width - 1
      let slot = first * MAX_ITEMS + last
      if first == last:
        table[slot] = prices[first] * year
      else:
        let sellFirst = prices[first] * year + table[(first + 1) * MAX_ITEMS + last]
        let sellLast = prices[last] * year + table[first * MAX_ITEMS + last - 1]
        table[slot] = max(sellFirst, sellLast)
  table[int(length) - 1]
