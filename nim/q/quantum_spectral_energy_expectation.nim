import std/math

const
  MaxN = 32
  Scale = 256'i64
  InvalidResult = -1.0e300
  Tau = 6.283185307179586476925286766559005768

proc fft(real, imag: var array[MaxN, float64], n: int, inverse: bool) =
  var j = 0
  for i in 1 ..< n:
    var bit = n shr 1
    while (j and bit) != 0:
      j = j xor bit
      bit = bit shr 1
    j = j xor bit
    if i < j:
      swap(real[i], real[j])
      swap(imag[i], imag[j])
  var width = 2
  while width <= n:
    let direction = if inverse: 1.0 else: -1.0
    let angle = direction * Tau / float64(width)
    let stepReal = cos(angle)
    let stepImag = sin(angle)
    let half = width shr 1
    for start in countup(0, n - width, width):
      var twiddleReal = 1.0
      var twiddleImag = 0.0
      for offset in 0 ..< half:
        let even = start + offset
        let odd = even + half
        let oddReal = real[odd] * twiddleReal - imag[odd] * twiddleImag
        let oddImag = real[odd] * twiddleImag + imag[odd] * twiddleReal
        real[odd] = real[even] - oddReal
        imag[odd] = imag[even] - oddImag
        real[even] += oddReal
        imag[even] += oddImag
        let nextReal = twiddleReal * stepReal - twiddleImag * stepImag
        twiddleImag = twiddleReal * stepImag + twiddleImag * stepReal
        twiddleReal = nextReal
    width = width shl 1
  if inverse:
    for i in 0 ..< n:
      real[i] /= float64(n)
      imag[i] /= float64(n)

proc quantum_spectral_energy_expectation*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "quantum_spectral_energy_expectation".} =
  if values == nil or length < 1 or length > csize_t(98): return InvalidResult
  let nValue = values[0]
  if nValue < 2 or nValue > MaxN or (nValue and (nValue - 1)) != 0: return InvalidResult
  let n = int(nValue)
  if length != csize_t(1 + 3 * n): return InvalidResult
  var norm = 0'i64
  for i in 0 ..< n:
    let potential = values[1 + i]
    let realQ = values[1 + n + i]
    let imagQ = values[1 + 2 * n + i]
    if potential < -2048 or potential > 2048 or realQ < -2048 or realQ > 2048 or
       imagQ < -2048 or imagQ > 2048: return InvalidResult
    norm += realQ * realQ + imagQ * imagQ
  if norm != Scale * Scale * nValue: return InvalidResult
  var real, imag: array[MaxN, float64]
  for i in 0 ..< n:
    real[i] = float64(values[1 + n + i]) / float64(Scale)
    imag[i] = float64(values[1 + 2 * n + i]) / float64(Scale)
  fft(real, imag, n, false)
  for i in 0 ..< n:
    let frequency = if i <= n div 2: int64(i) else: int64(i) - nValue
    let waveNumber = Tau * float64(frequency)
    let multiplier = 0.5 * waveNumber * waveNumber
    real[i] *= multiplier
    imag[i] *= multiplier
  fft(real, imag, n, true)
  var total = 0.0
  for i in 0 ..< n:
    let psiReal = float64(values[1 + n + i]) / float64(Scale)
    let psiImag = float64(values[1 + 2 * n + i]) / float64(Scale)
    let potential = float64(values[1 + i]) / float64(Scale)
    total += psiReal * (real[i] + potential * psiReal) +
             psiImag * (imag[i] + potential * psiImag)
  total / float64(n)
