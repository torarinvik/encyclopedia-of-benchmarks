const MaxStates = 3
const MaxText = 512
type Text = array[MaxText, char]

proc textLength(value: Text): int =
  while result < MaxText and value[result] != '\0': inc result

proc textFrom(value: string): Text =
  for index, character in value:
    if index < MaxText - 1: result[index] = character

proc textCompare(left, right: Text): int =
  let leftLength = textLength(left)
  let rightLength = textLength(right)
  let shared = min(leftLength, rightLength)
  for index in 0 ..< shared:
    if left[index] < right[index]: return -1
    if left[index] > right[index]: return 1
  if leftLength < rightLength: -1
  elif leftLength > rightLength: 1
  else: 0

proc regexUnion(left, right: Text): Text =
  let leftLength = textLength(left)
  let rightLength = textLength(right)
  if leftLength == 1 and left[0] == '#': return right
  if (rightLength == 1 and right[0] == '#') or textCompare(left, right) == 0: return left
  let first = if textCompare(left, right) < 0: left else: right
  let second = if textCompare(left, right) < 0: right else: left
  var position = 0
  result[position] = '('; inc position
  for index in 0 ..< textLength(first): result[position] = first[index]; inc position
  result[position] = '|'; inc position
  for index in 0 ..< textLength(second): result[position] = second[index]; inc position
  result[position] = ')'

proc regexConcat(left, right: Text): Text =
  let leftLength = textLength(left)
  let rightLength = textLength(right)
  if (leftLength == 1 and left[0] == '#') or (rightLength == 1 and right[0] == '#'):
    return textFrom("#")
  if leftLength == 1 and left[0] == '@': return right
  if rightLength == 1 and right[0] == '@': return left
  var position = 0
  result[position] = '('; inc position
  for index in 0 ..< leftLength: result[position] = left[index]; inc position
  result[position] = '.'; inc position
  for index in 0 ..< rightLength: result[position] = right[index]; inc position
  result[position] = ')'

proc regexStar(value: Text): Text =
  let length = textLength(value)
  if (length == 1 and value[0] == '#') or (length == 1 and value[0] == '@'):
    return textFrom("@")
  result[0] = '('
  for index in 0 ..< length: result[index + 1] = value[index]
  result[length + 1] = ')'
  result[length + 2] = '*'

proc brzozowski_dfa_to_regex*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "brzozowski_dfa_to_regex".} =
  if input.isNil or length < 3 or length > 10: return -1
  let nValue = input[0]
  let startValue = input[1]
  let accepting = input[2]
  if nValue < 1 or nValue > MaxStates or startValue < 0 or startValue >= nValue
      or accepting < 0 or accepting >= (1'i64 shl int(nValue))
      or length != csize_t(3 + 2 * nValue): return -1
  let n = int(nValue)
  let start = int(startValue)
  var coefficient: array[MaxStates, array[MaxStates, Text]]
  var constant: array[MaxStates, Text]
  for state in 0 ..< n:
    constant[state] = textFrom(if (accepting and (1'i64 shl state)) != 0: "@" else: "#")
    for target in 0 ..< n: coefficient[state][target] = textFrom("#")
    for symbol in 0 ..< 2:
      let nextValue = input[3 + 2 * state + symbol]
      if nextValue < 0 or nextValue >= nValue: return -1
      let next = int(nextValue)
      coefficient[state][next] = regexUnion(coefficient[state][next], textFrom($symbol))

  for pivot in 0 ..< n:
    if pivot == start: continue
    let loop = regexStar(coefficient[pivot][pivot])
    let pivotRow = coefficient[pivot]
    var pivotColumn: array[MaxStates, Text]
    for state in 0 ..< n: pivotColumn[state] = coefficient[state][pivot]
    let pivotConstant = constant[pivot]
    for source in 0 ..< n:
      if source == pivot: continue
      let prefix = regexConcat(pivotColumn[source], loop)
      for target in 0 ..< n:
        if target == pivot: continue
        let through = regexConcat(prefix, pivotRow[target])
        coefficient[source][target] = regexUnion(coefficient[source][target], through)
      let throughConstant = regexConcat(prefix, pivotConstant)
      constant[source] = regexUnion(constant[source], throughConstant)

  let answer = regexConcat(regexStar(coefficient[start][start]), constant[start])
  let resultLength = textLength(answer)
  if resultLength > 270: return -1
  if output.isNil or outputCapacity < csize_t(resultLength): return -2
  for index in 0 ..< resultLength: output[index] = uint8(ord(answer[index]))
  int64(resultLength)
