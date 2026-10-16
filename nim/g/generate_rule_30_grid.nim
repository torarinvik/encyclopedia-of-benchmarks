const MaxWidth = 64
const MaxGenerations = 64

proc generate_rule_30_grid*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "generate_rule_30_grid".} =
  if input == nil or length != 2: return -1
  let widthValue = input[0]
  let generationsValue = input[1]
  if widthValue < 1 or widthValue > MaxWidth or generationsValue < 1 or generationsValue > MaxGenerations: return -1
  let width = int(widthValue)
  let generations = int(generationsValue)
  let outputCount = width * generations
  if outputCapacity < csize_t(outputCount) or output == nil: return -2
  var current: array[MaxWidth, int64]
  var next: array[MaxWidth, int64]
  current[width div 2] = 1
  for column in 0 ..< width: output[column] = uint8(current[column])
  for generation in 1 ..< generations:
    for column in 0 ..< width:
      let left = if column > 0: current[column - 1] else: 0'i64
      let right = if column + 1 < width: current[column + 1] else: 0'i64
      let pattern = int(left * 4 + current[column] * 2 + right)
      next[column] = int64((30 shr pattern) and 1)
    for column in 0 ..< width:
      current[column] = next[column]
      output[generation * width + column] = uint8(next[column])
  int64(outputCount)
