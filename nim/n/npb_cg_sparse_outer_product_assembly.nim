import math

const MaxN = 16
const MaxNonzer = 4
const MaxSupport = 5
const MaxTriplets = 416
const MaxInput = 3 + 2 * MaxN * MaxNonzer
const MaxValueMicro = 1_000_000'i64
const MaxShiftMicro = 10_000_000'i64
const Scale = 1_000_000.0
const Rcond = 0.1

proc writeU64Le(output: ptr UncheckedArray[uint8], offset: var int, bits: uint64) =
  for byte in 0 ..< 8:
    output[offset] = uint8((bits shr (8 * byte)) and 0xFF'u64)
    inc offset

proc writeF64Le(output: ptr UncheckedArray[uint8], offset: var int, value: float64) =
  writeU64Le(output, offset, cast[uint64](value))

proc npb_cg_sparse_outer_product_assembly*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "npb_cg_sparse_outer_product_assembly".} =
  if input.isNil or int(length) < 3 or int(length) > MaxInput: return -1
  let nRaw = input[0]
  let nonzerRaw = input[1]
  if nRaw < 2 or nRaw > int64(MaxN) or nonzerRaw < 1 or nonzerRaw > int64(MaxNonzer) or
      input[2] < 0 or input[2] > MaxShiftMicro: return -1
  let n = int(nRaw)
  let nonzer = int(nonzerRaw)
  if int(length) != 3 + 2 * n * nonzer: return -1
  var cursor = 3
  for _vector in 0 ..< n:
    var seen = 0'u32
    for _entry in 0 ..< nonzer:
      let coordinate = input[cursor]
      let value = input[cursor + 1]
      cursor += 2
      if coordinate < 0 or coordinate >= int64(n) or value == 0 or
          value < -MaxValueMicro or value > MaxValueMicro: return -1
      let bit = 1'u32 shl int(coordinate)
      if (seen and bit) != 0: return -1
      seen = seen or bit

  var rawRows: array[MaxTriplets, uint8]
  var rawColumns: array[MaxTriplets, uint8]
  var rawValues: array[MaxTriplets, float64]
  var rawCount = 0
  cursor = 3
  for vector in 0 ..< n:
    var coordinates: array[MaxSupport, uint8]
    var vectorValues: array[MaxSupport, float64]
    var supportCount = nonzer
    var hasAnchor = false
    for entry in 0 ..< nonzer:
      let coordinate = int(input[cursor])
      coordinates[entry] = uint8(coordinate)
      vectorValues[entry] = float64(input[cursor + 1]) / Scale
      cursor += 2
      if coordinate == vector:
        vectorValues[entry] = 0.5
        hasAnchor = true
    if not hasAnchor:
      coordinates[supportCount] = uint8(vector)
      vectorValues[supportCount] = 0.5
      inc supportCount
    var weight = 1.0
    if vector == n - 1: weight = Rcond
    elif vector > 0: weight = pow(Rcond, float64(vector) / float64(n - 1))
    for columnSlot in 0 ..< supportCount:
      let scaledColumn = weight * vectorValues[columnSlot]
      for rowSlot in 0 ..< supportCount:
        rawRows[rawCount] = coordinates[rowSlot]
        rawColumns[rawCount] = coordinates[columnSlot]
        rawValues[rawCount] = vectorValues[rowSlot] * scaledColumn
        inc rawCount

  let diagonalAddend = Rcond - float64(input[2]) / Scale
  for diagonal in 0 ..< n:
    rawRows[rawCount] = uint8(diagonal)
    rawColumns[rawCount] = uint8(diagonal)
    rawValues[rawCount] = diagonalAddend
    inc rawCount

  var columnPointers: array[MaxN + 1, int64]
  var rowIndices: array[MaxN * MaxN, uint8]
  var matrixValues: array[MaxN * MaxN, float64]
  var nnz = 0
  for column in 0 ..< n:
    columnPointers[column] = int64(nnz)
    for row in 0 ..< n:
      var total = 0.0
      var touched = false
      for triple in 0 ..< rawCount:
        if int(rawRows[triple]) == row and int(rawColumns[triple]) == column:
          total += rawValues[triple]
          touched = true
      if touched:
        rowIndices[nnz] = uint8(row)
        matrixValues[nnz] = total
        inc nnz
  columnPointers[n] = int64(nnz)

  let required = 8 * (2 + (n + 1) + 2 * nnz)
  if output.isNil or int(capacity) < required: return -2
  var offset = 0
  writeF64Le(output, offset, float64(n))
  writeF64Le(output, offset, float64(nnz))
  for i in 0 .. n: writeF64Le(output, offset, float64(columnPointers[i]))
  for i in 0 ..< nnz: writeF64Le(output, offset, float64(rowIndices[i]))
  for i in 0 ..< nnz: writeF64Le(output, offset, matrixValues[i])
  int64(required)
