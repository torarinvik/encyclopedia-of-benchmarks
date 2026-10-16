proc dynamic_coin_change_solver*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "dynamic_coin_change_solver".} =
  if input == nil or length < 3 or length > 11: return -1
  let amountValue = input[0]
  let countValue = input[1]
  if amountValue < 1 or amountValue > 18 or countValue < 1 or countValue > 9 or int64(length) != countValue + 2: return -1
  let amount = int(amountValue)
  let count = int(countValue)
  var coins: array[9, int]
  var hasOne = false
  for i in 0 ..< count:
    if input[i + 2] < 1 or input[i + 2] > 9: return -1
    coins[i] = int(input[i + 2])
    if coins[i] == 1: hasOne = true
    for j in 0 ..< i:
      if coins[i] == coins[j]: return -1
  if not hasOne: return -1
  for i in 0 ..< count:
    for j in i + 1 ..< count:
      if coins[i] < coins[j]: swap(coins[i], coins[j])
  var changes: array[19, array[9, int]]
  var sizes: array[19, int]
  for value in 1 .. amount:
    for i in 0 ..< count:
      if coins[i] <= value:
        changes[value][sizes[value]] = value - coins[i]
        inc sizes[value]
  var current = amount
  var code = 0'i64
  for step in 0 ..< 18:
    var next = high(int)
    var minChange = high(int)
    for i in 0 ..< sizes[current]:
      let change = changes[current][i]
      if change == 0:
        next = 0
        break
      var minimum = high(int)
      for j in 0 ..< sizes[change]: minimum = min(minimum, changes[change][j])
      if minimum < minChange:
        minChange = minimum
        next = change
    if next == high(int): return -1
    code = code * 10 + int64(current - next)
    if next == 0: return code
    current = next
  return -1
