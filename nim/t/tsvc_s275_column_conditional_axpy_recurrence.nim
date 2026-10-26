import std/math

const MaxN = 8

proc tsvc_s275_column_conditional_axpy_recurrence*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s275_column_conditional_axpy_recurrence".} =
  if input.isNil or length < 2 or length > csize_t(193): return -1
  let rawN = input[0]
  if not rawN.isFinite or rawN != floor(rawN) or rawN < 1.0 or rawN > float64(MaxN): return -1
  let n = int(rawN)
  let cells = n * n
  if length != csize_t(1 + 3 * cells): return -1
  for i in 1 ..< int(length):
    if not input[i].isFinite or input[i] != floor(input[i]) or abs(input[i]) > 16.0: return -1
  if output.isNil or capacity < csize_t(cells): return -2
  var a: array[MaxN * MaxN, float64]
  for i in 0 ..< cells: a[i] = input[1 + i]
  let bs = 1 + cells
  let cs = 1 + 2 * cells
  for col in 0 ..< n:
    if a[col] > 0.0:
      for row in 1 ..< n:
        let index = row * n + col
        a[index] = a[index - n] + input[bs + index] * input[cs + index]
  for i in 0 ..< cells: output[i] = a[i]
  int64(cells)
