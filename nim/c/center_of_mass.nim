const InvalidResult = -1.0e300
const MaxParticles = 64
const MaxCoordinateUnits = 1_000_000'i64
const MaxMassUnits = 1_000_000'i64

proc roundTwoPython(value: float64): float64 =
  if value == 0.0: return value
  let negative = value < 0.0
  var normalized = if negative: -value else: value
  var exponent = 0
  while normalized >= 1.0:
    normalized *= 0.5
    inc exponent
  while normalized < 0.5:
    normalized *= 2.0
    dec exponent
  let significand = uint64(normalized * 9_007_199_254_740_992.0)
  let numerator = significand * 100'u64
  let shift = 53 - exponent
  var cents = 0'u64
  if shift < 0:
    cents = numerator shl (-shift)
  elif shift == 0:
    cents = numerator
  elif shift < 64:
    let denominator = 1'u64 shl shift
    cents = numerator shr shift
    let remainder = numerator and (denominator - 1)
    let half = denominator shr 1
    if remainder > half or (remainder == half and (cents and 1'u64) != 0): inc cents
  let rounded = float64(cents) / 100.0
  if negative: -rounded else: rounded

proc center_of_mass*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "center_of_mass".} =
  if values == nil or length < 2 or length > 258: return InvalidResult
  let selector = values[0]
  let countValue = values[1]
  if selector < 0 or selector > 2 or countValue < 1 or countValue > MaxParticles or
      length != csize_t(2 + 4 * countValue): return InvalidResult
  let count = int(countValue)
  for index in 0 ..< count:
    let offset = 2 + 4 * index
    for coordinate in 0 ..< 3:
      let unit = values[offset + coordinate]
      if unit < -MaxCoordinateUnits or unit > MaxCoordinateUnits: return InvalidResult
    let mass = values[offset + 3]
    if mass < 1 or mass > MaxMassUnits: return InvalidResult
  var totalMass = 0.0
  for index in 0 ..< count:
    totalMass += float64(values[2 + 4 * index + 3]) / 1000.0
  var weightedCoordinate = 0.0
  for index in 0 ..< count:
    let offset = 2 + 4 * index
    let coordinate = float64(values[offset + int(selector)]) / 1000.0
    let mass = float64(values[offset + 3]) / 1000.0
    weightedCoordinate += coordinate * mass
  roundTwoPython(weightedCoordinate / totalMass)
