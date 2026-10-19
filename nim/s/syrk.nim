import std/math

const MaxN = 8
const MaxM = 16

proc syrk*(input: ptr UncheckedArray[float64], length: csize_t,
           output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "syrk".} =
  if input.isNil or length != csize_t(2): return -1
  let nValue = input[0]
  let mValue = input[1]
  if not nValue.isFinite or not mValue.isFinite or
      nValue != floor(nValue) or mValue != floor(mValue) or
      nValue < 1.0 or nValue > float64(MaxN) or mValue < 1.0 or mValue > float64(MaxM): return -1
  let n = int(nValue)
  let m = int(mValue)
  const alpha = 1.5
  const beta = 1.2
  var a: array[MaxN * MaxM, float64]
  var c: array[MaxN * MaxN, float64]

  for i in 0 ..< n:
    for k in 0 ..< m:
      a[i * m + k] = float64((i * k + 1) mod n) / float64(n)
  for i in 0 ..< n:
    for j in 0 ..< n:
      c[i * n + j] = float64((i * j + 2) mod m) / float64(m)

  for i in 0 ..< n:
    for j in 0 .. i:
      c[i * n + j] *= beta
    for k in 0 ..< m:
      for j in 0 .. i:
        c[i * n + j] += alpha * a[i * m + k] * a[j * m + k]

  let required = n * n
  if output.isNil or capacity < csize_t(required): return -2
  for index in 0 ..< required: output[index] = c[index]
  int64(required)
