import math

const MaxN = 64
const MaxInputLength = 130
const Tau = 6.283185307179586476925286766559

proc direct_discrete_fourier_transform*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64 {.cdecl, exportc: "direct_discrete_fourier_transform".} =
  if input == nil or inputLength < 2 or inputLength > MaxInputLength: return -1
  for i in 0 ..< int(inputLength):
    if classify(input[i]) in {fcNan, fcInf, fcNegInf}: return -1
  let nValue = input[0]
  if nValue < 1.0 or nValue > float64(MaxN) or floor(nValue) != nValue: return -1
  let n = int(nValue)
  if inputLength != csize_t(1 + 2 * n): return -1
  for i in 0 ..< 2 * n:
    if input[i + 1] < -8.0 or input[i + 1] > 8.0: return -1

  let needed = 2 * n
  if output == nil or outputCapacity < csize_t(needed): return -2
  for k in 0 ..< n:
    var realSum = 0.0
    var imagSum = 0.0
    for j in 0 ..< n:
      let angle = -Tau * float64(j) * float64(k) / float64(n)
      let cosine = cos(angle)
      let sine = sin(angle)
      let sampleReal = input[1 + 2 * j]
      let sampleImag = input[2 + 2 * j]
      realSum += sampleReal * cosine + sampleImag * sine
      imagSum += sampleImag * cosine - sampleReal * sine
    output[2 * k] = realSum
    output[2 * k + 1] = imagSum
  int64(needed)

