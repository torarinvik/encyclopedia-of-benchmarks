## Clean-room bounded port of TSVC s4115; see package README for provenance.
const MaxN = 64
const MaxInputLength = 193
const MaxValue = 1_000_000'i64

proc tsvc_s4115_indexed_gather_product_sum*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "tsvc_s4115_indexed_gather_product_sum".} =
  if input.isNil or length < 4 or length > csize_t(MaxInputLength): return -1
  let nRaw = input[0]
  if nRaw < 1 or nRaw > MaxN: return -1
  let n = int(nRaw)
  if length != csize_t(1 + 3 * n): return -1

  for i in 0 ..< n:
    let index = input[1 + i]
    let aValue = input[1 + n + i]
    let bValue = input[1 + 2 * n + i]
    if index < 0 or index >= nRaw: return -1
    if aValue < 0 or aValue > MaxValue or bValue < 0 or bValue > MaxValue: return -1

  var total = 0'i64
  for i in 0 ..< n:
    let index = int(input[1 + i])
    total += input[1 + n + i] * input[1 + 2 * n + index]
  total
