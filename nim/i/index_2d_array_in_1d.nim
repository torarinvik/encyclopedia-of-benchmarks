## Retrieve one row-major flattened index from a rectangular matrix.
proc index_2d_array_in_1d*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "index_2d_array_in_1d".} =
  if input.isNil or length < 4: return -1
  let rows=input[0]; let cols=input[1]; let index=input[2]
  if rows < 1 or rows > 32 or cols < 1 or cols > 32: return -1
  let cells=rows*cols
  if length != csize_t(cells+3) or index < 0 or index >= cells: return -1
  for i in 0..<int(cells):
    if input[3+i] < 0 or input[3+i] > 1_000_000: return -1
  let row=index div cols; let col=index mod cols
  input[3+int(row*cols+col)]
