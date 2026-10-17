proc piecewise_linear_transform*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "piecewise_linear_transform".} =
  if input.isNil or length < 1 or length > 256: return -1
  for index in 0..<int(length):
    if input[index] < 0 or input[index] > 255: return -1
  if output.isNil or capacity < length: return -2
  for index in 0..<int(length):
    let pixel = float64(input[index])
    let mapped = if pixel <= 100.0:
      (50.0 / 100.0) * pixel
    elif pixel <= 180.0:
      ((200.0 - 50.0) / (180.0 - 100.0)) * (pixel - 100.0) + 50.0
    else:
      ((255.0 - 200.0) / (255.0 - 180.0)) * (pixel - 180.0) + 200.0
    output[index] = uint8(mapped)
  int64(length)
