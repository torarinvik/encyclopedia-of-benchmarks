import math

const MaxSide = 4
const MaxPoints = 64
const MaxSteps = 6
const ChecksumTerms = 64
const Tau = 6.28318530717958647692528676655900577
const Alpha = 0.000001

proc fftLine(real, imag: var array[MaxSide, float64], n: int, inverse: bool) =
  var reverse = 0
  for position in 1 ..< n:
    var bit = n shr 1
    while (reverse and bit) != 0:
      reverse = reverse xor bit
      bit = bit shr 1
    reverse = reverse xor bit
    if position < reverse:
      swap(real[position], real[reverse])
      swap(imag[position], imag[reverse])
  var block = 2
  while block <= n:
    let direction = if inverse: 1.0 else: -1.0
    let angle = direction * Tau / float64(block)
    let stepReal = cos(angle)
    let stepImag = sin(angle)
    for start in countup(0, n - 1, block):
      var weightReal = 1.0
      var weightImag = 0.0
      for offset in 0 ..< block div 2:
        let first = start + offset
        let second = first + block div 2
        let productReal = weightReal * real[second] - weightImag * imag[second]
        let productImag = weightReal * imag[second] + weightImag * real[second]
        let firstReal = real[first]
        let firstImag = imag[first]
        real[first] = firstReal + productReal
        imag[first] = firstImag + productImag
        real[second] = firstReal - productReal
        imag[second] = firstImag - productImag
        let nextReal = weightReal * stepReal - weightImag * stepImag
        weightImag = weightReal * stepImag + weightImag * stepReal
        weightReal = nextReal
    block *= 2
  if inverse:
    for i in 0 ..< n:
      real[i] /= float64(n)
      imag[i] /= float64(n)

proc axisTransform(real, imag: var array[MaxPoints, float64], n, axis: int, inverse: bool) =
  for a in 0 ..< n:
    for b in 0 ..< n:
      var lineReal, lineImag: array[MaxSide, float64]
      for p in 0 ..< n:
        var x = a
        var y = b
        var z = p
        if axis == 0: (x, y, z) = (p, a, b)
        elif axis == 1: (x, y, z) = (a, p, b)
        let index = (x * n + y) * n + z
        lineReal[p] = real[index]
        lineImag[p] = imag[index]
      fftLine(lineReal, lineImag, n, inverse)
      for p in 0 ..< n:
        var x = a
        var y = b
        var z = p
        if axis == 0: (x, y, z) = (p, a, b)
        elif axis == 1: (x, y, z) = (a, p, b)
        let index = (x * n + y) * n + z
        real[index] = lineReal[p]
        imag[index] = lineImag[p]

proc transform3d(real, imag: var array[MaxPoints, float64], n: int, inverse: bool) =
  axisTransform(real, imag, n, 2, inverse)
  axisTransform(real, imag, n, 1, inverse)
  axisTransform(real, imag, n, 0, inverse)

proc signedFrequency(index, n: int): int =
  if index <= n div 2: index else: index - n

proc npb_ft_3d_spectral_step*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64 {.cdecl, exportc: "npb_ft_3d_spectral_step".} =
  if input == nil or inputLength < 2 or inputLength > 130: return -1
  if input[0] != 2.0 and input[0] != 4.0: return -1
  if input[1] < 1.0 or input[1] > float64(MaxSteps) or floor(input[1]) != input[1]: return -1
  let n = int(input[0])
  let steps = int(input[1])
  let volume = n * n * n
  if inputLength != csize_t(2 + 2 * volume): return -1
  for i in 2 ..< int(inputLength):
    if input[i] != input[i] or input[i] < -1.0 or input[i] > 1.0: return -1
  let needed = 2 * steps
  if output == nil or outputCapacity < csize_t(needed): return -2

  var spectrumReal, spectrumImag, workReal, workImag: array[MaxPoints, float64]
  for i in 0 ..< volume:
    spectrumReal[i] = input[2 + 2 * i]
    spectrumImag[i] = input[2 + 2 * i + 1]
  transform3d(spectrumReal, spectrumImag, n, false)
  for step in 1 .. steps:
    for x in 0 ..< n:
      for y in 0 ..< n:
        for z in 0 ..< n:
          let index = (x * n + y) * n + z
          let kx = signedFrequency(x, n)
          let ky = signedFrequency(y, n)
          let kz = signedFrequency(z, n)
          let radiusSquared = float64(kx * kx + ky * ky + kz * kz)
          let factor = exp(-39.47841760435743447533796399950460 * Alpha * float64(step) * radiusSquared)
          workReal[index] = spectrumReal[index] * factor
          workImag[index] = spectrumImag[index] * factor
    transform3d(workReal, workImag, n, true)
    var sumReal, sumImag = 0.0
    for j in 1 .. ChecksumTerms:
      let x = (j - 1) mod n
      let y = (3 * j - 1) mod n
      let z = (5 * j - 1) mod n
      let index = (x * n + y) * n + z
      sumReal += workReal[index]
      sumImag += workImag[index]
    output[2 * (step - 1)] = sumReal / float64(volume)
    output[2 * (step - 1) + 1] = sumImag / float64(volume)
  int64(needed)
