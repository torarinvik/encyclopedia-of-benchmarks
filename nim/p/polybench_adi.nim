const MaxDimension = 32
const MaxCells = MaxDimension * MaxDimension
const MaxTsteps = 20'i64

proc writeF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc polybench_adi*(values: ptr UncheckedArray[int64], length: csize_t,
                    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "polybench_adi".} =
  if values.isNil or length != 2 or values[0] < 1 or values[0] > MaxDimension or
      values[1] < 1 or values[1] > MaxTsteps: return -1
  let n = int(values[0])
  let tsteps = int(values[1])
  let cells = n * n
  let outputBytes = cells * 8
  if output.isNil or csize_t(outputBytes) > outputCapacity: return -2

  var u: array[MaxCells, float64]
  var v: array[MaxCells, float64]
  var p: array[MaxCells, float64]
  var q: array[MaxCells, float64]
  for i in 0 ..< n:
    for j in 0 ..< n:
      u[i * n + j] = float64(i + n - j) / float64(n)

  let dx = 1.0 / float64(n)
  let dy = 1.0 / float64(n)
  let dt = 1.0 / float64(tsteps)
  let b1 = 2.0
  let b2 = 1.0
  let mul1 = b1 * dt / (dx * dx)
  let mul2 = b2 * dt / (dy * dy)
  let a = -mul1 / 2.0
  let b = 1.0 + mul1
  let c = a
  let d = -mul2 / 2.0
  let e = 1.0 + mul2
  let f = d

  for _ in 1 .. tsteps:
    for i in 1 ..< n - 1:
      v[i] = 1.0
      p[i * n] = 0.0
      q[i * n] = v[i]
      for j in 1 ..< n - 1:
        p[i * n + j] = -c / (a * p[i * n + j - 1] + b)
        q[i * n + j] = (-d * u[j * n + i - 1] + (1.0 + 2.0 * d) * u[j * n + i]
                        - f * u[j * n + i + 1] - a * q[i * n + j - 1]) /
                       (a * p[i * n + j - 1] + b)
      v[(n - 1) * n + i] = 1.0
      var j = n - 1
      while j > 1:
        dec j
        v[j * n + i] = p[i * n + j] * v[(j + 1) * n + i] + q[i * n + j]

    for i in 1 ..< n - 1:
      u[i * n] = 1.0
      p[i * n] = 0.0
      q[i * n] = u[i * n]
      for j in 1 ..< n - 1:
        p[i * n + j] = -f / (d * p[i * n + j - 1] + e)
        q[i * n + j] = (-a * v[(i - 1) * n + j] + (1.0 + 2.0 * a) * v[i * n + j]
                        - c * v[(i + 1) * n + j] - d * q[i * n + j - 1]) /
                       (d * p[i * n + j - 1] + e)
      u[i * n + n - 1] = 1.0
      var j = n - 1
      while j > 1:
        dec j
        u[i * n + j] = p[i * n + j] * u[i * n + j + 1] + q[i * n + j]

  for index in 0 ..< cells:
    writeF64Le(output, index * 8, u[index])
  int64(outputBytes)
