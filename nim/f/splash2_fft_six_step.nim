import math

const MaxPoints = 64
const MaxOutput = 128
const Tau = 6.283185307179586476925286766559

proc transpose(source: var array[MaxOutput, float64], destination: var array[MaxOutput, float64], side: int) =
  for row in 0 ..< side:
    for column in 0 ..< side:
      let fromIndex = 2 * (row * side + column)
      let toIndex = 2 * (column * side + row)
      destination[toIndex] = source[fromIndex]
      destination[toIndex + 1] = source[fromIndex + 1]

proc fftRow(data: var array[MaxOutput, float64], base, side: int) =
  var reverse = 0
  for position in 1 ..< side:
    var bit = side shr 1
    while (reverse and bit) != 0:
      reverse = reverse xor bit
      bit = bit shr 1
    reverse = reverse xor bit
    if position < reverse:
      let left = 2 * (base + position)
      let right = 2 * (base + reverse)
      swap(data[left], data[right])
      swap(data[left + 1], data[right + 1])
  var block = 2
  while block <= side:
    let half = block div 2
    let angleStep = Tau / float64(block)
    for start in countup(0, side - 1, block):
      for offset in 0 ..< half:
        let angle = angleStep * float64(offset)
        let weightReal = cos(angle)
        let weightImag = -sin(angle)
        let first = 2 * (base + start + offset)
        let second = 2 * (base + start + offset + half)
        let productReal = weightReal * data[second] - weightImag * data[second + 1]
        let productImag = weightReal * data[second + 1] + weightImag * data[second]
        let firstReal = data[first]
        let firstImag = data[first + 1]
        data[first] = firstReal + productReal
        data[first + 1] = firstImag + productImag
        data[second] = firstReal - productReal
        data[second + 1] = firstImag - productImag
    block *= 2

proc splash2_fft_six_step*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64 {.cdecl, exportc: "splash2_fft_six_step".} =
  if input == nil or inputLength < 9 or inputLength > 130: return -1
  if input[0] != 2.0 and input[0] != 4.0 and input[0] != 8.0: return -1
  let side = int(input[0])
  let points = side * side
  if inputLength != csize_t(1 + 2 * points): return -1
  for i in 0 ..< int(inputLength):
    if input[i] != input[i]: return -1
  for i in 1 ..< int(inputLength):
    if input[i] < -8.0 or input[i] > 8.0: return -1

  var firstMatrix, secondMatrix: array[MaxOutput, float64]
  for i in 0 ..< 2 * points: firstMatrix[i] = input[i + 1]
  transpose(firstMatrix, secondMatrix, side)
  for row in 0 ..< side: fftRow(secondMatrix, row * side, side)
  for row in 0 ..< side:
    for column in 0 ..< side:
      let index = 2 * (row * side + column)
      let angle = Tau * float64(row * column) / float64(points)
      let cosine = cos(angle)
      let sine = sin(angle)
      let real = secondMatrix[index]
      let imag = secondMatrix[index + 1]
      secondMatrix[index] = cosine * real + sine * imag
      secondMatrix[index + 1] = cosine * imag - sine * real
  transpose(secondMatrix, firstMatrix, side)
  for row in 0 ..< side: fftRow(firstMatrix, row * side, side)
  transpose(firstMatrix, secondMatrix, side)

  let needed = 2 * points
  if output == nil or outputCapacity < csize_t(needed): return -2
  for i in 0 ..< needed: output[i] = secondMatrix[i]
  int64(needed)
