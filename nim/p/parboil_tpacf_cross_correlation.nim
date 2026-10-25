import std/math

const MaxPoints = 4
const NumBins = 20
const MaxInputLength = 26
const PiValue = 3.141592653589793238462643383279502884

proc f32FromRaw(value: int64): float32 = float32(value) / 1_000_000'f32

proc parboil_tpacf_cross_correlation*(input: ptr UncheckedArray[int64],
    inputLength: csize_t, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "parboil_tpacf_cross_correlation".} =
  if input == nil or inputLength < 8 or inputLength > MaxInputLength: return -1
  let dataValue = input[0]
  let randomValue = input[1]
  if dataValue < 1 or dataValue > MaxPoints or randomValue < 1 or randomValue > MaxPoints: return -1
  let dataCount = int(dataValue)
  let randomCount = int(randomValue)
  if inputLength != csize_t(2 + 3 * (dataCount + randomCount)): return -1
  for i in 2..<int(inputLength):
    if input[i] < -1_000_000 or input[i] > 1_000_000: return -1
  if output == nil or outputCapacity < NumBins: return -2

  var boundaries: array[NumBins + 1, float32]
  for k in 0..NumBins:
    let exponent = log10(1.0) + float64(k) * 1.0 / 5.0
    let arcminutes = pow(10.0, exponent)
    let radians = arcminutes / 60.0 * (PiValue / 180.0)
    boundaries[k] = float32(cos(radians))
  var histogram: array[NumBins, uint8]
  let randomBase = 2 + 3 * dataCount
  for j in 0..<randomCount:
    let rx = f32FromRaw(input[randomBase + 3*j])
    let ry = f32FromRaw(input[randomBase + 3*j + 1])
    let rz = f32FromRaw(input[randomBase + 3*j + 2])
    for i in 0..<dataCount:
      let dx = f32FromRaw(input[2 + 3*i])
      let dy = f32FromRaw(input[2 + 3*i + 1])
      let dz = f32FromRaw(input[2 + 3*i + 2])
      let px = dx * rx; let py = dy * ry; let pz = dz * rz
      let xy = px + py
      let distance = xy + pz
      var min = 0; var max = NumBins
      while max > min + 1:
        let middle = (min + max) div 2
        if distance >= boundaries[middle]: max = middle else: min = middle
      if distance < boundaries[min] and distance >= boundaries[max]: inc histogram[max - 1]
  for bin in 0..<NumBins: output[bin] = histogram[bin]
  return NumBins
