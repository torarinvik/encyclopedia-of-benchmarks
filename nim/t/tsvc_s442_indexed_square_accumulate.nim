## Clean-room bounded port of TSVC s442; see package README for provenance.
const MaxN = 64
const MaxPasses = 16
const MaxInputLength = 386

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc tsvc_s442_indexed_square_accumulate*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s442_indexed_square_accumulate".} =
  if input.isNil or length < 8 or length > csize_t(MaxInputLength): return -1
  if input[0] < 1 or input[0] > MaxN or input[1] < 1 or input[1] > MaxPasses: return -1
  let n = int(input[0])
  let passes = int(input[1])
  if length != csize_t(2 + 6 * n): return -1
  var a, b, c, d, e, selector: array[MaxN, int64]
  for i in 0 ..< n:
    a[i] = input[2 + i]
    b[i] = input[2 + n + i]
    c[i] = input[2 + 2 * n + i]
    d[i] = input[2 + 3 * n + i]
    e[i] = input[2 + 4 * n + i]
    selector[i] = input[2 + 5 * n + i]
    if a[i] < -2 or a[i] > 2 or b[i] < -2 or b[i] > 2 or
        c[i] < -2 or c[i] > 2 or d[i] < -2 or d[i] > 2 or
        e[i] < -2 or e[i] > 2 or selector[i] < 1 or selector[i] > 4: return -1
  if output.isNil or capacity < csize_t(8 * n): return -2
  for round in 0 ..< passes:
    for i in 0 ..< n:
      let selected = case selector[i]
        of 1: b[i]
        of 2: c[i]
        of 3: d[i]
        else: e[i]
      a[i] += selected * selected
  for i in 0 ..< n: storeI64Le(output, 8 * i, a[i])
  int64(n)
