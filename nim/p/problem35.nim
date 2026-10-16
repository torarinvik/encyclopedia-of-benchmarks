const MaxLimit = 1_000_000
const OddSlots = MaxLimit div 2 + 1

proc problem35*(ignored: int64): int64 {.cdecl, exportc: "problem35".} =
  if ignored != 0: return -1
  var oddPrime: array[OddSlots, bool]
  for index in 1 ..< OddSlots: oddPrime[index] = true

  var candidate = 3
  while candidate <= MaxLimit div candidate:
    if oddPrime[candidate div 2]:
      var composite = candidate * candidate
      while composite <= MaxLimit:
        oddPrime[composite div 2] = false
        composite += 2 * candidate
    candidate += 2

  var count: int64 = 1
  var number = 3
  while number <= MaxLimit:
    if oddPrime[number div 2]:
      var remaining = number
      var hasEvenDigit = false
      while remaining > 0:
        if (remaining mod 10) mod 2 == 0:
          hasEvenDigit = true
          break
        remaining = remaining div 10
      if not hasEvenDigit:
        var power10 = 1
        var digits = 1
        remaining = number
        while remaining >= 10:
          power10 *= 10
          remaining = remaining div 10
          inc digits
        var rotation = number
        var circular = true
        for _ in 0 ..< digits:
          if not oddPrime[rotation div 2]:
            circular = false
            break
          rotation = (rotation mod 10) * power10 + rotation div 10
        if circular: inc count
    number += 2
  count
