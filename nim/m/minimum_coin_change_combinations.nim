const MaxInput = 34

proc minimum_coin_change_combinations*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "minimum_coin_change_combinations".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let targetValue = input[0]
  let countValue = input[1]
  if targetValue < -64 or targetValue > 64 or countValue < 0 or countValue > 32: return -1
  let count = int(countValue)
  if int(length) != count + 2: return -1

  var previous = 0'i64
  for index in 0 ..< count:
    let coin = input[2 + index]
    if coin < 1 or coin > 64 or coin <= previous: return -1
    previous = coin

  if targetValue < 0: return 0
  let target = int(targetValue)
  var ways: array[65, int64]
  ways[0] = 1
  for coinIndex in 0 ..< count:
    let coin = int(input[2 + coinIndex])
    for amount in coin .. target:
      ways[amount] += ways[amount - coin]
  ways[target]
