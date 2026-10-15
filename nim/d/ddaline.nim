proc javaRound(value: float64): int64 =
  let shifted = value + 0.5
  result = int64(shifted)
  if float64(result) > shifted: dec result

proc writeI64(output: ptr UncheckedArray[uint8], position: var int, value: int64) =
  for shift in countup(0, 56, 8):
    output[position] = uint8((value shr shift) and 255)
    inc position

proc ddaline*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "ddaline".} =
  if input.isNil or length != 4: return -1
  for i in 0..<4:
    if input[i] < -128 or input[i] > 128: return -1
  let dx = input[2] - input[0]
  let dy = input[3] - input[1]
  let steps = max(abs(dx), abs(dy))
  if steps > 256: return -1
  let outputBytes = (int(steps) + 1) * 16
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var position = 0
  if steps == 0:
    writeI64(output, position, input[0])
    writeI64(output, position, input[1])
    return 16
  let xIncrement = float64(dx) / float64(steps)
  let yIncrement = float64(dy) / float64(steps)
  var x = float64(input[0])
  var y = float64(input[1])
  for _ in 0..int(steps):
    writeI64(output, position, javaRound(x))
    writeI64(output, position, javaRound(y))
    x += xIncrement
    y += yIncrement
  int64(outputBytes)
