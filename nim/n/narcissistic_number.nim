## Enumerate narcissistic numbers below limit, memoizing digit powers.
proc narcissistic_number*(limit: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "narcissistic_number".} =
  if limit > 100000: return -1
  if limit <= 0: return 0
  var numbers: array[32, int64]
  var powers: array[60, int64]
  var cached: array[60, bool]
  var count = 0
  var number = 0'i64
  while number < limit:
    var digits = 1
    var remaining = number
    while remaining >= 10:
      remaining = remaining div 10
      inc digits
    var sum = 0'i64
    remaining = number
    while remaining > 0:
      let digit = int(remaining mod 10)
      let key = digits * 10 + digit
      if not cached[key]:
        var power = 1'i64
        for _ in 0 ..< digits: power *= int64(digit)
        powers[key] = power
        cached[key] = true
      sum += powers[key]
      remaining = remaining div 10
    if sum == number:
      if count == numbers.len: return -1
      numbers[count] = number
      inc count
    inc number
  let required = count * 8
  if required == 0: return 0
  if output == nil or outputCapacity < csize_t(required): return -2
  var position = 0
  for item in 0 ..< count:
    let value = uint64(numbers[item])
    for byte in 0 ..< 8:
      output[position] = uint8((value shr ((7 - byte) * 8)) and 0xff'u64)
      inc position
  int64(required)
