const MaxPosition = 678_910'i64
const Log10Two = 0.30102999566398114
const LowerLimit = 0.08990511143939792
const UpperLimit = 0.09342168516223506
const RoundScale = 1_000_000_000_000_000.0

proc roundedDecimalPart(exponent: int64): float64 =
  let logarithm = Log10Two * float64(exponent)
  let integerPart = int64(logarithm)
  let scaled = (logarithm - float64(integerPart)) * RoundScale
  var rounded = int64(scaled)
  let remainder = scaled - float64(rounded)
  if remainder > 0.5 or (remainder == 0.5 and rounded mod 2 != 0): inc rounded
  float64(rounded) / RoundScale

proc problem686*(number: int64): int64 {.cdecl, exportc: "problem686".} =
  if number < 1 or number > MaxPosition: return -1
  var power = 90'i64
  var position = 0'i64
  var previous = 0'i64
  while position < number:
    let difference = roundedDecimalPart(power)
    if difference >= UpperLimit: power += 93
    elif difference < LowerLimit: power += 196
    else:
      previous = power
      power += 196
      inc position
  previous
