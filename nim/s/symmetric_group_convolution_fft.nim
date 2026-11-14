## Uncompiled ABI draft. Nim allocation failure may terminate rather than return -3.
import symmetric_group_convolution_fft_plan
import symmetric_group_convolution_fft_forward
import symmetric_group_convolution_fft_inverse

proc symmetric_group_convolution_fft*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "symmetric_group_convolution_fft".} =
  if input.isNil or length < 1 or length > 725762: return -1
  if input[0] < 1 or input[0] > 9: return -1
  let n = int(input[0])
  let count = Factorials[n]
  if length != csize_t(1 + 2 * count): return -1
  for i in 1 ..< int(length):
    if input[i] < 0 or input[i] >= Modulus: return -1
  if output.isNil or capacity < csize_t(4 * count): return -2
  try:
    var leftInput = newSeq[int64](count)
    var rightInput = newSeq[int64](count)
    for i in 0 ..< count:
      leftInput[i] = input[1 + i]
      rightInput[i] = input[1 + count + i]
    let levels = makeLevels(n)
    let left = forward(levels, n, leftInput)
    let right = forward(levels, n, rightInput)
    var product = newSeq[FourierBlock](levels[n].len)
    for shape, rep in levels[n]:
      let d = rep.basis.len
      product[shape] = newSeq[int64](d * d)
      for row in 0 ..< d:
        for inner in 0 ..< d:
          for col in 0 ..< d:
            let index = row * d + col
            product[shape][index] = (product[shape][index] +
              left[shape][row * d + inner] * right[shape][inner * d + col]) mod Modulus
    let coefficients = inverse(levels, n, product)
    if coefficients.len != count: return -4
    for i in 0 ..< count:
      let value = uint32(coefficients[i])
      for byteIndex in 0 ..< 4:
        output[4 * i + byteIndex] = uint8((value shr (8 * byteIndex)) and 255'u32)
    int64(4 * count)
  except PlanError:
    -4
