proc multiplyDigits(digits: var array[512, int], length, factor: int): int =
  var carry = 0
  var count = length
  for i in 0 ..< length:
    let value = digits[i] * factor + carry
    digits[i] = value mod 10
    carry = value div 10
  while carry > 0:
    digits[count] = carry mod 10
    inc count
    carry = carry div 10
  count

proc problem56*(a, b: int64): int64 {.cdecl, exportc: "problem56".} =
  if a < 1 or a > 200 or b < 1 or b > 200: return -1
  var best = 0'i64
  for base in 0 ..< int(a):
    var digits: array[512, int]
    digits[0] = 1
    var length = 1
    for power in 0 ..< int(b):
      var sum = 0'i64
      for i in 0 ..< length: sum += int64(digits[i])
      if sum > best: best = sum
      if power + 1 < int(b): length = multiplyDigits(digits, length, base)
  best
