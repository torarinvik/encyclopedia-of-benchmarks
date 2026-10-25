## Clean-room port of TSVC s281; see the package README for provenance and rights.

const MaxN = 16
const MaxInputLength = 50

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 0xff'u64)
    bits = bits shr 8

proc tsvc_s281_reverse_coupled_update*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s281_reverse_coupled_update".} =
  if input.isNil or inputLength < 5 or inputLength > MaxInputLength: return -1
  if input[0] < 1 or input[0] > MaxN or input[1] < 1 or input[1] > 8: return -1
  let n = int(input[0])
  let passes = int(input[1])
  if inputLength != csize_t(2 + 3 * n): return -1

  var a: array[MaxN, float64]
  var b: array[MaxN, float64]
  var c: array[MaxN, float64]
  for i in 0 ..< n:
    let av = input[2 + i]
    let bv = input[2 + n + i]
    let cv = input[2 + 2 * n + i]
    if av < -2 or av > 2 or bv < -2 or bv > 2 or cv < -1 or cv > 1: return -1
    a[i] = float64(av)
    b[i] = float64(bv)
    c[i] = float64(cv)

  let outputBytes = 16 * n
  if output.isNil or outputCapacity < csize_t(outputBytes): return -2
  for pass in 0 ..< passes:
    for i in 0 ..< n:
      let x = a[n - i - 1] + b[i] * c[i]
      a[i] = x - 1.0
      b[i] = x
  for i in 0 ..< n:
    storeI64Le(output, 8 * i, int64(a[i]))
    storeI64Le(output, 8 * (n + i), int64(b[i]))
  int64(outputBytes)
