type I64Input = ptr UncheckedArray[int64]
type ByteOutput = ptr UncheckedArray[uint8]

proc appendU64(valueInput: uint64, output: ByteOutput, capacity: csize_t,
               position: var csize_t): bool =
  var value = valueInput
  var digits: array[20, uint8]
  var count = 0
  while true:
    digits[count] = uint8(ord('0') + int(value mod 10'u64))
    inc count
    value = value div 10'u64
    if value == 0: break
  if csize_t(count) > capacity - position: return false
  while count > 0:
    dec count
    output[position] = digits[count]
    inc position
  true

proc allocation_number*(values: I64Input, length: csize_t, output: ByteOutput,
                         outputCapacity: csize_t): int64 {.cdecl, exportc: "allocation_number".} =
  if length != 2: return -1
  if values[0] < 1'i64 or values[0] > 1_000_000'i64 or values[1] < 1'i64 or
     values[1] > 128'i64 or values[1] > values[0]: return -1
  let total = uint64(values[0])
  let partitions = uint64(values[1])
  let block = total div partitions
  var position = csize_t(0)
  var index = 0'u64
  while index < partitions:
    let start = index * block + 1
    let finish = if index + 1 == partitions: total else: (index + 1) * block
    if not appendU64(start, output, outputCapacity, position): return -2
    if position >= outputCapacity: return -2
    output[position] = uint8(ord('-'))
    inc position
    if not appendU64(finish, output, outputCapacity, position): return -2
    if index + 1 != partitions:
      if position >= outputCapacity: return -2
      output[position] = uint8(ord(','))
      inc position
    inc index
  int64(position)
