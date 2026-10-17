const MaxLength = 6

proc emitRow(values: var array[MaxLength, int32], length: int,
    output: ptr UncheckedArray[uint8], offset: var int) =
  for index in 0 ..< length:
    let bits = cast[uint32](values[index])
    for byte in 0 ..< 4:
      output[offset] = uint8((bits shr (8 * byte)) and 255'u32)
      inc offset

proc steinhaus_johnson_trotter*(input: ptr UncheckedArray[int32], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "steinhaus_johnson_trotter".} =
  if input == nil or length == 0 or length > csize_t(MaxLength): return -1
  let count = int(length)
  var permutations = 1
  var factor = 2
  while factor <= count:
    permutations *= factor
    inc factor
  let required = 4 * count * permutations
  if output == nil or outputCapacity < csize_t(required): return -2

  var values: array[MaxLength, int32]
  var inversion: array[MaxLength, int]
  for index in 0 ..< count: values[index] = input[index]
  var offset = 0
  emitRow(values, count, output, offset)

  var index = 1
  while index < count:
    if inversion[index] < index:
      let swapIndex = if index mod 2 == 0: 0 else: inversion[index]
      swap(values[swapIndex], values[index])
      emitRow(values, count, output, offset)
      inc inversion[index]
      index = 1
    else:
      inversion[index] = 0
      inc index
  int64(required)
