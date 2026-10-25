## Clean-room port of TSVC s244; see package README for provenance and rights.
const MaxN = 32
const MaxInputLength = 129

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc tsvc_s244_false_dependence_cycle_break*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s244_false_dependence_cycle_break".} =
  if input.isNil or length < 9 or length > csize_t(MaxInputLength): return -1
  if input[0] < 2 or input[0] > MaxN: return -1
  let n = int(input[0])
  if length != csize_t(1 + 4 * n): return -1
  var a, b, c, d: array[MaxN, int64]
  var trace: array[MaxN - 1, int64]
  for i in 0 ..< n:
    a[i] = input[1 + i]
    b[i] = input[1 + n + i]
    c[i] = input[1 + 2 * n + i]
    d[i] = input[1 + 3 * n + i]
    if a[i] < -2 or a[i] > 2 or b[i] < -2 or b[i] > 2 or
        c[i] < -2 or c[i] > 2 or d[i] < -2 or d[i] > 2: return -1
  let outputValues = 3 * n - 1
  if output.isNil or capacity < csize_t(8 * outputValues): return -2
  for i in 0 ..< n - 1:
    a[i] = b[i] + c[i] * d[i]
    b[i] = c[i] + b[i]
    a[i + 1] = b[i] + a[i + 1] * d[i]
    trace[i] = a[i + 1]
  var offset = 0
  for i in 0 ..< n:
    storeI64Le(output, 8 * offset, a[i])
    inc offset
  for i in 0 ..< n:
    storeI64Le(output, 8 * offset, b[i])
    inc offset
  for i in 0 ..< n - 1:
    storeI64Le(output, 8 * offset, trace[i])
    inc offset
  int64(outputValues)
