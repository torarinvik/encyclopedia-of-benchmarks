const MaxYears = 16
const MaxValueMicro = 1_000_000_000_000'i64
const MaxRatePpm = 1_000_000'i64
const MaxUnits = 1_000_000_000'i64

proc writeF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc depreciation*(values: ptr UncheckedArray[int64], length: csize_t,
                   output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "depreciation".} =
  if values.isNil or length < 4 or length > MaxYears + 4: return -1
  let selector = values[0]
  var years = 0
  var purchaseScaled = 0'i64
  var residualScaled = 0'i64
  var rate = 0.0
  if selector == 0 or selector == 3 or selector == 4:
    if length != 4 or values[1] < 1 or values[1] > MaxYears: return -1
    years = int(values[1])
    purchaseScaled = values[2]; residualScaled = values[3]
  elif selector == 1:
    if length != 5 or values[1] < 1 or values[1] > MaxYears or
       values[4] < 1 or values[4] > MaxRatePpm: return -1
    years = int(values[1])
    purchaseScaled = values[2]; residualScaled = values[3]
    rate = float64(values[4]) / 1_000_000.0
  elif selector == 2:
    if length < 5: return -1
    years = int(length) - 4
    if years > MaxYears or values[3] < 1 or values[3] > MaxUnits: return -1
    purchaseScaled = values[1]; residualScaled = values[2]
    var unitSum = 0.0
    for index in 0 ..< years:
      if values[4 + index] < -MaxUnits or values[4 + index] > MaxUnits: return -1
      unitSum += float64(values[4 + index])
    if abs(unitSum - float64(values[3])) > 1.0e-6 * float64(values[3]): return -1
  else:
    return -1

  if purchaseScaled < 0 or purchaseScaled > MaxValueMicro or
     residualScaled < -MaxValueMicro or residualScaled > purchaseScaled: return -1
  let purchase = float64(purchaseScaled) / 1_000_000.0
  let residual = float64(residualScaled) / 1_000_000.0
  let depreciableCost = purchase - residual
  var schedule: array[MaxYears, float64]

  if selector == 0:
    let annual = depreciableCost / float64(years)
    var accumulated = 0.0
    for period in 0 ..< years:
      if period == years - 1: schedule[period] = depreciableCost - accumulated
      else:
        accumulated += annual
        schedule[period] = annual
  elif selector == 1:
    var bookValue = purchase
    for period in 0 ..< years:
      if period == years - 1: schedule[period] = bookValue - residual
      else:
        let expense = min(bookValue * rate, bookValue - residual)
        schedule[period] = expense
        bookValue -= expense
  elif selector == 2:
    let perUnit = depreciableCost / float64(values[3])
    var accumulated = 0.0
    for period in 0 ..< years:
      if period == years - 1: schedule[period] = depreciableCost - accumulated
      else:
        let expense = float64(values[4 + period]) * perUnit
        accumulated += expense
        schedule[period] = expense
  elif selector == 3:
    let syd = float64(years) * (float64(years) + 1.0) / 2.0
    var accumulated = 0.0
    for period in 1 .. years:
      if period == years: schedule[period - 1] = depreciableCost - accumulated
      else:
        let expense = (float64(years - period + 1) / syd) * depreciableCost
        accumulated += expense
        schedule[period - 1] = expense
  else:
    let ddbRate = 2.0 / float64(years)
    var bookValue = purchase
    var accumulated = 0.0
    for period in 1 .. years:
      let remaining = float64(years - period + 1)
      let ddb = max(bookValue * ddbRate, 0.0)
      let straightLine = max((bookValue - residual) / remaining, 0.0)
      let expense = min(max(ddb, straightLine), bookValue - residual)
      if period == years: schedule[period - 1] = depreciableCost - accumulated
      else:
        accumulated += expense
        schedule[period - 1] = expense
        bookValue -= expense

  let outputBytes = years * 8
  if output.isNil or outputBytes > int(outputCapacity): return -2
  for index in 0 ..< years: writeF64Le(output, index * 8, schedule[index])
  int64(outputBytes)
