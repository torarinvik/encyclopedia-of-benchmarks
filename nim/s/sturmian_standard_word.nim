type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

const
  MaxSteps = 4
  MaxWord = 41

proc sturmian_standard_word*(values: I64Input, length: csize_t,
    output: U8Output, capacity: csize_t): int64
    {.cdecl, exportc: "sturmian_standard_word".} =
  if values == nil or length < 1 or length > 6: return -1
  let stepsWord = values[0]
  if stepsWord < 0 or stepsWord > MaxSteps.int64: return -1
  let steps = int(stepsWord)
  if length != csize_t(steps + 1): return -1

  var directives: array[MaxSteps, int64]
  for i in 0 ..< steps:
    let repeat = values[i + 1]
    if (i == 0 and (repeat < 0 or repeat > 2)) or
       (i != 0 and (repeat < 1 or repeat > 2)):
      return -1
    directives[i] = repeat

  var previous, current, following: array[MaxWord, uint8]
  previous[0] = uint8('b')
  current[0] = uint8('a')
  var previousLength = 1
  var currentLength = 1
  for step in 0 ..< steps:
    let repeat = int(directives[step])
    let followingLength = currentLength * repeat + previousLength
    var position = 0
    for _ in 0 ..< repeat:
      for i in 0 ..< currentLength:
        following[position] = current[i]
        inc position
    for i in 0 ..< previousLength:
      following[position] = previous[i]
      inc position
    for i in 0 ..< currentLength: previous[i] = current[i]
    for i in 0 ..< followingLength: current[i] = following[i]
    previousLength = currentLength
    currentLength = followingLength

  if output == nil or capacity < csize_t(currentLength): return -2
  for i in 0 ..< currentLength: output[i] = current[i]
  int64(currentLength)
