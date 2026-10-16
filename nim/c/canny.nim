const
  MaxSide = 16
  MaxPixels = MaxSide * MaxSide
  NormScale = 1_048_576'i64
  AngleScale = 1_000_000_000'i64
  Tan22_5Q9 = 414_213_562'i64
  Gaussian = [
    85_321'i64, 66_110, 30_754, 8_589, 1_440,
    66_110, 51_225, 23_829, 6_655, 1_116,
    30_754, 23_829, 11_085, 3_096, 519,
    8_589, 6_655, 3_096, 865, 145,
    1_440, 1_116, 519, 145, 24
  ]
  SobelX = [-1'i64, 0, 1, -2, 0, 2, -1, 0, 1]
  SobelY = [1'i64, 2, 1, 0, 0, 0, -1, -2, -1]

proc clampCoordinate(coordinate, side: int): int {.inline.} =
  if coordinate < 0: return 0
  if coordinate >= side: return side - 1
  coordinate

proc integerSqrt(value: uint64): uint64 =
  if value < 2: return value
  var low = 1'u64
  var high = min(value, 4_294_967_296'u64)
  while low <= high:
    let middle = low + (high - low) div 2
    if middle <= value div middle:
      low = middle + 1
    else:
      high = middle - 1
  high

proc canny*(values: ptr UncheckedArray[int64], length: csize_t,
            output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
            {.cdecl, exportc: "canny".} =
  if values == nil or length < 2 or length > csize_t(1 + MaxPixels): return -1
  let sideValue = values[0]
  if sideValue < 1 or sideValue > MaxSide: return -1
  let side = int(sideValue)
  let pixels = side * side
  if int(length) != pixels + 1: return -1
  for index in 0 ..< pixels:
    if values[index + 1] < 0 or values[index + 1] > 255: return -1
  if outputCapacity < csize_t(pixels) or output == nil: return -2

  var blurred: array[MaxPixels, int64]
  var gradientX: array[MaxPixels, int64]
  var gradientY: array[MaxPixels, int64]
  var normalizedX: array[MaxPixels, int64]
  var normalizedY: array[MaxPixels, int64]
  var magnitude: array[MaxPixels, int64]
  var destination: array[MaxPixels, int64]

  for row in 0 ..< side:
    for column in 0 ..< side:
      var total = 0'i64
      for ky in -4 .. 4:
        let sourceRow = clampCoordinate(row + ky, side)
        for kx in -4 .. 4:
          let sourceColumn = clampCoordinate(column + kx, side)
          total += Gaussian[abs(ky) * 5 + abs(kx)] * values[1 + sourceRow * side + sourceColumn]
      blurred[row * side + column] = total

  var maximumX = 0'i64
  var maximumY = 0'i64
  for row in 0 ..< side:
    for column in 0 ..< side:
      var totalX = 0'i64
      var totalY = 0'i64
      for ky in -1 .. 1:
        let sourceRow = clampCoordinate(row + ky, side)
        for kx in -1 .. 1:
          let sourceColumn = clampCoordinate(column + kx, side)
          let sample = blurred[sourceRow * side + sourceColumn]
          let kernelIndex = (ky + 1) * 3 + kx + 1
          totalX += sample * SobelX[kernelIndex]
          totalY += sample * SobelY[kernelIndex]
      let offset = row * side + column
      gradientX[offset] = abs(totalX)
      gradientY[offset] = abs(totalY)
      maximumX = max(maximumX, gradientX[offset])
      maximumY = max(maximumY, gradientY[offset])

  var maximumMagnitude = 0'u64
  for index in 0 ..< pixels:
    if maximumX != 0: normalizedX[index] = gradientX[index] * 255 * NormScale div maximumX
    if maximumY != 0: normalizedY[index] = gradientY[index] * 255 * NormScale div maximumY
    let x = uint64(normalizedX[index])
    let y = uint64(normalizedY[index])
    magnitude[index] = int64(integerSqrt(x * x + y * y))
    maximumMagnitude = max(maximumMagnitude, uint64(magnitude[index]))
  if maximumMagnitude != 0:
    for index in 0 ..< pixels:
      magnitude[index] = magnitude[index] * 255 div int64(maximumMagnitude)

  for row in 1 ..< side - 1:
    for column in 1 ..< side - 1:
      let offset = row * side + column
      var before = offset - 1
      var after = offset + 1
      if normalizedY[offset] * AngleScale >= normalizedX[offset] * Tan22_5Q9:
        if normalizedX[offset] * AngleScale <= normalizedY[offset] * Tan22_5Q9:
          before = offset - side
          after = offset + side
        else:
          before = offset + side - 1
          after = offset - side + 1
      if magnitude[offset] >= magnitude[before] and magnitude[offset] >= magnitude[after]:
        destination[offset] = magnitude[offset]

  for index in 0 ..< pixels:
    if destination[index] >= 30: destination[index] = 255
    elif destination[index] <= 15: destination[index] = 0
    else: destination[index] = 128
  for row in 1 ..< side - 1:
    for column in 1 ..< side - 1:
      let offset = row * side + column
      if destination[offset] == 128:
        var connected = false
        for dy in -1 .. 1:
          for dx in -1 .. 1:
            if (dx != 0 or dy != 0) and destination[(row + dy) * side + column + dx] == 255:
              connected = true
        destination[offset] = if connected: 255 else: 0
  for index in 0 ..< pixels:
    output[index] = uint8(destination[index])
  int64(pixels)
