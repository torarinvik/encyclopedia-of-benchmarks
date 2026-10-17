const MaxInputLength = 129

proc strassenMultiply(a, b, c: ptr UncheckedArray[int64], n: int) =
  if n == 1:
    c[0] = a[0] * b[0]
    return
  let h = n div 2
  var x, y: array[16, int64]
  var m1, m2, m3, m4, m5, m6, m7: array[16, int64]
  for r in 0 ..< h:
    for col in 0 ..< h:
      let i = r * h + col
      x[i] = a[r * n + col] + a[(r + h) * n + col + h]
      y[i] = b[r * n + col] + b[(r + h) * n + col + h]
  strassenMultiply(cast[ptr UncheckedArray[int64]](addr x[0]), cast[ptr UncheckedArray[int64]](addr y[0]), cast[ptr UncheckedArray[int64]](addr m1[0]), h)
  for r in 0 ..< h:
    for col in 0 ..< h:
      let i = r * h + col
      x[i] = a[(r + h) * n + col] + a[(r + h) * n + col + h]
      y[i] = b[r * n + col]
  strassenMultiply(cast[ptr UncheckedArray[int64]](addr x[0]), cast[ptr UncheckedArray[int64]](addr y[0]), cast[ptr UncheckedArray[int64]](addr m2[0]), h)
  for r in 0 ..< h:
    for col in 0 ..< h:
      let i = r * h + col
      x[i] = a[r * n + col]
      y[i] = b[r * n + col + h] - b[(r + h) * n + col + h]
  strassenMultiply(cast[ptr UncheckedArray[int64]](addr x[0]), cast[ptr UncheckedArray[int64]](addr y[0]), cast[ptr UncheckedArray[int64]](addr m3[0]), h)
  for r in 0 ..< h:
    for col in 0 ..< h:
      let i = r * h + col
      x[i] = a[(r + h) * n + col + h]
      y[i] = b[(r + h) * n + col] - b[r * n + col]
  strassenMultiply(cast[ptr UncheckedArray[int64]](addr x[0]), cast[ptr UncheckedArray[int64]](addr y[0]), cast[ptr UncheckedArray[int64]](addr m4[0]), h)
  for r in 0 ..< h:
    for col in 0 ..< h:
      let i = r * h + col
      x[i] = a[r * n + col] + a[r * n + col + h]
      y[i] = b[(r + h) * n + col + h]
  strassenMultiply(cast[ptr UncheckedArray[int64]](addr x[0]), cast[ptr UncheckedArray[int64]](addr y[0]), cast[ptr UncheckedArray[int64]](addr m5[0]), h)
  for r in 0 ..< h:
    for col in 0 ..< h:
      let i = r * h + col
      x[i] = a[(r + h) * n + col] - a[r * n + col]
      y[i] = b[r * n + col] + b[r * n + col + h]
  strassenMultiply(cast[ptr UncheckedArray[int64]](addr x[0]), cast[ptr UncheckedArray[int64]](addr y[0]), cast[ptr UncheckedArray[int64]](addr m6[0]), h)
  for r in 0 ..< h:
    for col in 0 ..< h:
      let i = r * h + col
      x[i] = a[r * n + col + h] - a[(r + h) * n + col + h]
      y[i] = b[(r + h) * n + col] + b[(r + h) * n + col + h]
  strassenMultiply(cast[ptr UncheckedArray[int64]](addr x[0]), cast[ptr UncheckedArray[int64]](addr y[0]), cast[ptr UncheckedArray[int64]](addr m7[0]), h)
  for r in 0 ..< h:
    for col in 0 ..< h:
      let i = r * h + col
      c[r * n + col] = m1[i] + m4[i] - m5[i] + m7[i]
      c[r * n + col + h] = m3[i] + m5[i]
      c[(r + h) * n + col] = m2[i] + m4[i]
      c[(r + h) * n + col + h] = m1[i] - m2[i] + m3[i] + m6[i]

proc strassen_matrix_multiplication*(input: ptr UncheckedArray[int64], length: csize_t,
                                    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "strassen_matrix_multiplication".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  if nValue != 1 and nValue != 2 and nValue != 4 and nValue != 8: return -1
  let n = int(nValue)
  let cells = n * n
  if length != csize_t(1 + 2 * cells): return -1
  for i in 0 ..< 2 * cells:
    if input[1 + i] < -2 or input[1 + i] > 2: return -1
  let outputBytes = csize_t(8 * cells)
  if output == nil or capacity < outputBytes: return -2
  var result: array[64, int64]
  strassenMultiply(cast[ptr UncheckedArray[int64]](unsafeAddr input[1]),
    cast[ptr UncheckedArray[int64]](unsafeAddr input[1 + cells]),
    cast[ptr UncheckedArray[int64]](addr result[0]), n)
  for i in 0 ..< cells:
    let bits = cast[uint64](result[i])
    for byte in 0 ..< 8:
      output[i * 8 + byte] = uint8((bits shr (8 * byte)) and 255)
  int64(outputBytes)
