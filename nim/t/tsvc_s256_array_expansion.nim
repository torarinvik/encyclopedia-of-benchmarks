## Clean-room bounded port of TSVC s256; see package README for provenance.
const MaxN = 16
const MaxCells = MaxN * MaxN
const MaxInputLength = 2 + MaxN + 2 * MaxCells
const MaxC0 = 1_000_000'i64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc tsvc_s256_array_expansion*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s256_array_expansion".} =
  if input.isNil or length < 5 or length > csize_t(MaxInputLength): return -1
  let nRaw = input[0]
  let a0 = input[1]
  if nRaw < 1 or nRaw > MaxN or a0 < -1000 or a0 > 1000: return -1
  let n = int(nRaw)
  let cells = n * n
  if length != csize_t(2 + n + 2 * cells): return -1
  let dStart = 2
  let bStart = dStart + n
  let cStart = bStart + cells
  for i in 0 ..< n:
    if input[dStart + i] < -1000 or input[dStart + i] > 1000: return -1
  for i in 0 ..< cells:
    if input[bStart + i] < -1000 or input[bStart + i] > 1000 or
       input[cStart + i] < -MaxC0 or input[cStart + i] > MaxC0: return -1

  let outputValues = n + cells
  if output.isNil or outputCapacity < csize_t(outputValues * 8): return -2
  var a: array[MaxN, int64]
  var c: array[MaxCells, int64]
  a[0] = a0
  for cell in 0 ..< cells: c[cell] = input[cStart + cell]
  for column in 0 ..< n:
    for row in 1 ..< n:
      a[row] = 1 - a[row - 1]
      let cell = row * n + column
      c[cell] = a[row] + input[bStart + cell] * input[dStart + row]
  for row in 0 ..< n: storeI64Le(output, row * 8, a[row])
  for cell in 0 ..< cells: storeI64Le(output, (n + cell) * 8, c[cell])
  int64(outputValues)
