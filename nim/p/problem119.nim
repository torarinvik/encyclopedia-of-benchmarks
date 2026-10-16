proc digitSum(valueIn: int64): int64 =
  var value = valueIn
  while value > 0:
    result += value mod 10
    value = value div 10

proc problem119*(index: int64): int64 {.cdecl, exportc: "problem119".} =
  if index < 1 or index > 30: return -1
  var values: array[10000, int64]
  var count = 0
  for base in 2'i64..<100'i64:
    var value = base * base
    for exponent in 2..<100:
      if digitSum(value) == base:
        values[count] = value
        inc count
      if value > high(int64) div base: break
      value *= base
  for i in 1..<count:
    let value = values[i]
    var j = i
    while j > 0 and values[j - 1] > value:
      values[j] = values[j - 1]
      dec j
    values[j] = value
  values[int(index - 1)]
