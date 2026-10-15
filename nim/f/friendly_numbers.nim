## Preserve the pinned JavaScript FriendlyNumbers divisor-loop behavior.
proc abundancyIndex(number: uint64): float64 =
  var sum = number
  var divisor = 1'u64
  while divisor * 2 < number:
    if number mod divisor == 0: sum += divisor
    inc divisor
  float64(sum) / float64(number)

proc friendly_numbers*(first, second: uint64): int64 {.cdecl, exportc: "friendly_numbers".} =
  if first == 0 or second == 0 or first == second or first > 1000 or second > 1000: return -1
  if abundancyIndex(first) == abundancyIndex(second): 1 else: 0
