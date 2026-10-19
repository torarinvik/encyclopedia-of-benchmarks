import std/math

const MaxWidth = 32
const MaxHeight = 32
const MaxPixels = MaxWidth * MaxHeight
const InvalidResult = -1e300

type Pixels = array[MaxPixels, float32]

proc filterOnce(width, height: int, image: Pixels, output: var Pixels,
    y1, y2: var Pixels) =
  let alpha = 0.25'f32
  let expNegAlpha = float32(exp(-float64(alpha)))
  let difference = 1.0'f32 - expNegAlpha
  let numerator = difference * difference
  let denominatorLeft = 1.0'f32 + 2.0'f32 * alpha * expNegAlpha
  let k = numerator / (denominatorLeft - float32(exp(2.0'f32 * alpha)))
  let a1 = k
  let a2 = k * expNegAlpha * (alpha - 1.0'f32)
  let a3 = k * expNegAlpha * (alpha + 1.0'f32)
  let a4 = -k * float32(exp(-2.0'f32 * alpha))
  let a5 = k
  let a6 = a2
  let a7 = a3
  let a8 = a4
  let b1 = float32(pow(2.0'f32, -alpha))
  let b2 = -float32(exp(-2.0'f32 * alpha))
  for i in 0 ..< width:
    var ym1 = 0.0'f32
    var ym2 = 0.0'f32
    var xm1 = 0.0'f32
    for j in 0 ..< height:
      let at = i * height + j
      var value = a1 * image[at] + a2 * xm1
      value = value + b1 * ym1
      value = value + b2 * ym2
      y1[at] = value
      xm1 = image[at]
      ym2 = ym1
      ym1 = value
  for i in 0 ..< width:
    var yp1 = 0.0'f32
    var yp2 = 0.0'f32
    var xp1 = 0.0'f32
    var xp2 = 0.0'f32
    for j in countdown(height - 1, 0):
      let at = i * height + j
      var value = a3 * xp1 + a4 * xp2
      value = value + b1 * yp1
      value = value + b2 * yp2
      y2[at] = value
      xp2 = xp1
      xp1 = image[at]
      yp2 = yp1
      yp1 = value
  for i in 0 ..< width:
    for j in 0 ..< height:
      let at = i * height + j
      output[at] = 1.0'f32 * (y1[at] + y2[at])
  for j in 0 ..< height:
    var tm1 = 0.0'f32
    var ym1 = 0.0'f32
    var ym2 = 0.0'f32
    for i in 0 ..< width:
      let at = i * height + j
      var value = a5 * output[at] + a6 * tm1
      value = value + b1 * ym1
      value = value + b2 * ym2
      y1[at] = value
      tm1 = output[at]
      ym2 = ym1
      ym1 = value
  for j in 0 ..< height:
    var tp1 = 0.0'f32
    var tp2 = 0.0'f32
    var yp1 = 0.0'f32
    var yp2 = 0.0'f32
    for i in countdown(width - 1, 0):
      let at = i * height + j
      var value = a7 * tp1 + a8 * tp2
      value = value + b1 * yp1
      value = value + b2 * yp2
      y2[at] = value
      tp2 = tp1
      tp1 = output[at]
      yp2 = yp1
      yp1 = value
  for at in 0 ..< width * height: output[at] = 1.0'f32 * (y1[at] + y2[at])

proc deriche*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "deriche".} =
  if values == nil or length != 3: return InvalidResult
  if values[0] < 1 or values[0] > MaxWidth or values[1] < 1 or values[1] > MaxHeight or
      values[2] < 1 or values[2] > 4: return InvalidResult
  let width = int(values[0])
  let height = int(values[1])
  var image: Pixels
  var output: Pixels
  var y1: Pixels
  var y2: Pixels
  for i in 0 ..< width:
    for j in 0 ..< height:
      image[i * height + j] = float32((313 * i + 991 * j) mod 65536) / 65535.0'f32
  for pass in 0 ..< int(values[2]):
    filterOnce(width, height, image, output, y1, y2)
    for at in 0 ..< width * height: image[at] = output[at]
  var checksum = 0.0'f64
  for at in 0 ..< width * height: checksum += float64(output[at])
  checksum
