## Compute the six exact 5x5 determinant coefficients of a conic.
proc determinant(features: array[5, array[6, int64]], columns: array[5, int]): int64 =
  var paths: array[32, int64]
  paths[0] = 1
  for row in 0 ..< 5:
    var next: array[32, int64]
    for mask in 0 ..< 32:
      var selected = 0
      for bitIndex in 0 ..< 5:
        if (mask and (1 shl bitIndex)) != 0: inc selected
      if selected != row or paths[mask] == 0: continue
      for column in 0 ..< 5:
        let bit = 1 shl column
        if (mask and bit) != 0: continue
        var inversions = 0
        for previous in column + 1 ..< 5:
          if (mask and (1 shl previous)) != 0: inc inversions
        let term = paths[mask] * features[row][columns[column]]
        if inversions mod 2 == 0: next[mask or bit] += term
        else: next[mask or bit] -= term
    paths = next
  paths[31]

proc braikenridge_maclaurin_construction*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "braikenridge_maclaurin_construction".} =
  if values == nil or length != 10: return -2
  var features: array[5, array[6, int64]]
  for point in 0 ..< 5:
    let x = values[point * 2]
    let y = values[point * 2 + 1]
    if x < -10 or x > 10 or y < -10 or y > 10: return -2
    features[point] = [x * x, x * y, y * y, x, y, 1'i64]
  const columns: array[6, array[5, int]] = [
    [1, 2, 3, 4, 5], [0, 2, 3, 4, 5], [0, 1, 3, 4, 5],
    [0, 1, 2, 4, 5], [0, 1, 2, 3, 5], [0, 1, 2, 3, 4]]
  const signs: array[6, int64] = [1, -1, 1, -1, 1, -1]
  var coefficients: array[6, int64]
  for index in 0 ..< 6:
    coefficients[index] = signs[index] * determinant(features, columns[index])
  if outputCapacity < 48 or output == nil: return -2
  for index in 0 ..< 6:
    let bits = cast[uint64](coefficients[index])
    for byte in 0 ..< 8:
      output[index * 8 + byte] = uint8((bits shr (byte * 8)) and 0xff)
  6
