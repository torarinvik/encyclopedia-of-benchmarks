const MaxSeriesLength = 16
const MaxSampleValue = 1000'i64
const InvalidResult = -1.0e300
const Unreachable = 1.0e300

proc dynamic_time_warping*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "dynamic_time_warping".} =
  if values == nil or length < 3 or length > 35: return InvalidResult
  let firstLengthValue = values[0]
  let secondLengthValue = values[1]
  let bandValue = values[2]
  if firstLengthValue < 1 or firstLengthValue > MaxSeriesLength or
      secondLengthValue < 1 or secondLengthValue > MaxSeriesLength: return InvalidResult
  let firstLength = int(firstLengthValue)
  let secondLength = int(secondLengthValue)
  if bandValue < abs(firstLengthValue - secondLengthValue) or bandValue > MaxSeriesLength or
      length != csize_t(3 + firstLength + secondLength): return InvalidResult
  let band = int(bandValue)
  for index in 0 ..< firstLength + secondLength:
    let value = values[3 + index]
    if value < -MaxSampleValue or value > MaxSampleValue: return InvalidResult

  var rows: array[2, array[MaxSeriesLength + 1, float64]]
  for column in 0 .. secondLength: rows[0][column] = Unreachable
  rows[0][0] = 0.0
  for row in 1 .. firstLength:
    let current = row mod 2
    let previous = (row - 1) mod 2
    for column in 0 .. secondLength: rows[current][column] = Unreachable
    let start = max(1, row - band)
    let finish = min(secondLength, row + band)
    for column in start .. finish:
      let difference = abs(values[3 + row - 1] - values[3 + firstLength + column - 1])
      var best = rows[previous][column]
      if rows[current][column - 1] < best: best = rows[current][column - 1]
      if rows[previous][column - 1] < best: best = rows[previous][column - 1]
      rows[current][column] = float64(difference) + best
  rows[firstLength mod 2][secondLength]
