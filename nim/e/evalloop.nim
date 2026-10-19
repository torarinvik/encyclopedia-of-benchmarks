const
  MinPasses = 0'i64
  MaxPasses = 1_000'i64
  BufferSize = 2_048
  StagedCapacity = 14

proc execute(sum: var uint32, opcode: int32) =
  sum = sum + uint32(opcode)

proc eval(commands: ptr UncheckedArray[int32], sum: var uint32) =
  var pc = 0
  var opcode = commands[pc]
  inc pc
  while opcode != 0:
    if opcode < 1 or opcode > 31: return
    execute(sum, opcode)
    opcode = commands[pc]
    inc pc

proc formatOutput(sumInput: uint32, staged: var array[StagedCapacity, uint8]): int =
  staged[0] = 83'u8
  staged[1] = 117'u8
  staged[2] = 109'u8
  staged[3] = 58'u8
  staged[4] = 32'u8
  var used = 5
  var reversed: array[10, uint8]
  var digits = 0
  var sum = sumInput
  while true:
    reversed[digits] = uint8(48'u32 + sum mod 10'u32)
    inc digits
    sum = sum div 10'u32
    if sum == 0: break
  while digits > 0:
    dec digits
    staged[used] = reversed[digits]
    inc used
  staged[used] = 10'u8
  inc used
  used

proc evalloop*(passes: int64, output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64 {.cdecl, exportc: "evalloop".} =
  if passes < MinPasses or passes > MaxPasses: return -1
  if output.isNil: return -2

  var commands: array[BufferSize, int32]
  for index in 0 ..< BufferSize - 1: commands[index] = int32(index mod 31 + 1)
  var sum = 0'u32
  for _ in 0 ..< int(passes): eval(cast[ptr UncheckedArray[int32]](addr commands[0]), sum)

  var staged: array[StagedCapacity, uint8]
  let used = formatOutput(sum, staged)
  if outputCapacity < csize_t(used): return -2
  for index in 0 ..< used: output[index] = staged[index]
  int64(used)
