## Port the fixed-size integer matrix multiplication from Stanford IntMM.
const RowSize = 40
const CellCount = RowSize * RowSize
const MaxPasses = 10

proc decimalWidth(value: int32): int =
  var magnitude = int64(value)
  if magnitude < 0: magnitude = -magnitude
  result = if value < 0: 1 else: 0
  while true:
    inc result
    magnitude = magnitude div 10
    if magnitude == 0: break

proc writeDecimal(value: int32, output: ptr UncheckedArray[uint8], position: var int) =
  var magnitude = int64(value)
  if magnitude < 0:
    output[position] = uint8(ord('-'))
    inc position
    magnitude = -magnitude
  var reversed: array[10, uint8]
  var count = 0
  while true:
    reversed[count] = uint8(48 + magnitude mod 10)
    inc count
    magnitude = magnitude div 10
    if magnitude == 0: break
  while count > 0:
    dec count
    output[position] = reversed[count]
    inc position

proc stanford_intmm*(passCount: int64, output: ptr UncheckedArray[uint8],
                     outputCapacity: csize_t): int64 {.cdecl, exportc: "stanford_intmm".} =
  if passCount < 1 or passCount > MaxPasses: return -1

  var a: array[CellCount, int32]
  var b: array[CellCount, int32]
  var product: array[CellCount, int32]
  var diagonal: array[MaxPasses, int32]
  for pass in 0 ..< int(passCount):
    var seed = 74755'i64
    for index in 0 ..< CellCount:
      seed = (seed * 1309 + 13849) and 65535
      a[index] = int32(seed mod 120 - 60)
    for index in 0 ..< CellCount:
      seed = (seed * 1309 + 13849) and 65535
      b[index] = int32(seed mod 120 - 60)

    for row in 0 ..< RowSize:
      for column in 0 ..< RowSize:
        var sum = 0'i32
        for inner in 0 ..< RowSize:
          sum += a[row * RowSize + inner] * b[inner * RowSize + column]
        product[row * RowSize + column] = sum
    diagonal[pass] = product[pass * RowSize + pass]

  var required = 0
  for pass in 0 ..< int(passCount):
    required += decimalWidth(diagonal[pass]) + 1
  if output.isNil or outputCapacity < csize_t(required): return -2

  var position = 0
  for pass in 0 ..< int(passCount):
    writeDecimal(diagonal[pass], output, position)
    output[position] = uint8(ord('\n'))
    inc position
  int64(position)
