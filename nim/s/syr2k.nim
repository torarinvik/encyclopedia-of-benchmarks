import std/math

const MaxN = 8
const MaxM = 16
type F64Input = ptr UncheckedArray[float64]
type F64Output = ptr UncheckedArray[float64]

proc syr2k*(input: F64Input, length: csize_t, output: F64Output,
            capacity: csize_t): int64 {.cdecl, exportc: "syr2k".} =
  if input.isNil or length != csize_t(2): return -1
  let nValue = input[0]
  let mValue = input[1]
  if not nValue.isFinite or not mValue.isFinite or
      nValue != floor(nValue) or mValue != floor(mValue) or
      nValue < 1.0 or nValue > float64(MaxN) or
      mValue < 1.0 or mValue > float64(MaxM): return -1
  let n = int(nValue)
  let m = int(mValue)
  const alpha = 1.5
  const beta = 1.2
  var a: array[MaxN * MaxM, float64]
  var b: array[MaxN * MaxM, float64]
  var c: array[MaxN * MaxN, float64]

  for i in 0 ..< n:
    for j in 0 ..< m:
      a[i * m + j] = float64((i * j + 1) mod n) / float64(n)
      b[i * m + j] = float64((i * j + 2) mod m) / float64(m)
  for i in 0 ..< n:
    for j in 0 ..< n:
      c[i * n + j] = float64((i * j + 3) mod n) / float64(m)

  for i in 0 ..< n:
    for j in 0 .. i:
      c[i * n + j] *= beta
    for k in 0 ..< m:
      for j in 0 .. i:
        c[i * n + j] += a[j * m + k] * alpha * b[i * m + k] + b[j * m + k] * alpha * a[i * m + k]

  let required = n * n
  if output.isNil or capacity < csize_t(required): return -2
  for index in 0 ..< required: output[index] = c[index]
  int64(required)
