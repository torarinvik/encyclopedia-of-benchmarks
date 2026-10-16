const MaxLimit = 28123

proc problem23*(limit: int64): int64 {.cdecl, exportc: "problem23".} =
  if limit < 0 or limit > MaxLimit: return -1
  let bound = int(limit)
  var properDivisorSums: array[MaxLimit + 1, int64]
  var abundant: array[MaxLimit + 1, bool]
  var representable: array[MaxLimit + 1, bool]

  var divisor = 1
  while divisor <= bound div 2:
    var multiple = 2 * divisor
    while multiple <= bound:
      properDivisorSums[multiple] += int64(divisor)
      multiple += divisor
    inc divisor

  var value = 12
  while value <= bound:
    abundant[value] = properDivisorSums[value] > int64(value)
    inc value

  var left = 12
  while left <= bound:
    if abundant[left]:
      var right = left
      while right <= bound - left:
        if abundant[right]:
          representable[left + right] = true
        inc right
    inc left

  var total: int64 = 0
  value = 1
  while value <= bound:
    if not representable[value]: total += int64(value)
    inc value
  total
