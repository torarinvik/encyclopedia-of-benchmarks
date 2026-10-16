const MaxTarget = 8

type I64Input = ptr UncheckedArray[int64]
type ByteOutput = ptr UncheckedArray[uint8]

proc requiredBytes(remaining, depth: int): int =
  if remaining == 0: return depth + 1
  for face in 1 .. min(remaining, 6):
    result += requiredBytes(remaining - face, depth + 1)

proc emitCombinations(remaining, depth: int, digits: var array[MaxTarget, uint8],
    output: ByteOutput, position: var int) =
  if remaining == 0:
    for index in 0 ..< depth:
      output[position] = digits[index]
      inc position
    output[position] = uint8(ord('\n'))
    inc position
    return
  for face in 1 .. min(remaining, 6):
    digits[depth] = uint8(ord('0') + face)
    emitCombinations(remaining - face, depth + 1, digits, output, position)

proc dice_thrower*(values: I64Input, length: csize_t, output: ByteOutput,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "dice_thrower".} =
  if values == nil or length != 1 or values[0] < 0 or values[0] > MaxTarget: return -1
  let target = int(values[0])
  let needed = requiredBytes(target, 0)
  if int(outputCapacity) < needed or output == nil: return -2
  var digits: array[MaxTarget, uint8]
  var position = 0
  emitCombinations(target, 0, digits, output, position)
  int64(position)
