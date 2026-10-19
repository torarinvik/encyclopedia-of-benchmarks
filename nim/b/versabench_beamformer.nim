const InputLength = 48
proc versabench_beamformer*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "versabench_beamformer".} =
  if input == nil or length != csize_t(InputLength): return -1
  var values: array[InputLength, float32]
  for i in 0 ..< InputLength:
    let x = input[i]
    if x != x or x < -128.0 or x > 128.0: return -1
    values[i] = float32(x)
  var real = 0.0'f32
  var imag = 0.0'f32
  for channel in 0 ..< 12:
    let b = 4 * channel
    let rr = values[b] * values[b + 2] - values[b + 1] * values[b + 3]
    let ii = values[b] * values[b + 3] + values[b + 1] * values[b + 2]
    real = real + rr
    imag = imag + ii
  if output == nil or capacity < csize_t(2): return -2
  output[0] = float64(real)
  output[1] = float64(imag)
  2
