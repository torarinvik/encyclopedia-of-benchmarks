const MaxDims = 65
const MaxDimension = 1000'i64
const MaxCells = MaxDims * MaxDims

proc matrix_chain_multiplication*(dimensions: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "matrix_chain_multiplication".} =
  if length > MaxDims: return -1
  let n = int(length)
  for index in 0 ..< n:
    if dimensions[index] < 1 or dimensions[index] > MaxDimension: return -1
  if n < 2: return 0

  let matrixCount = n - 1
  var costs: array[MaxCells, int64]
  for index in 0 ..< MaxCells: costs[index] = 0
  for chainLength in 2 .. matrixCount:
    for start in 0 .. matrixCount - chainLength:
      let finish = start + chainLength - 1
      var best = high(int64)
      for split in start ..< finish:
        let cost = costs[start * MaxDims + split] + costs[(split + 1) * MaxDims + finish] + dimensions[start] * dimensions[split + 1] * dimensions[finish + 1]
        if cost < best: best = cost
      costs[start * MaxDims + finish] = best
  costs[matrixCount - 1]
