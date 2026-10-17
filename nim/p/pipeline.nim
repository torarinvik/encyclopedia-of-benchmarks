const MaxStageCount = 32
const MaxInputLength = 2 + 2 * MaxStageCount

proc pipeline*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "pipeline".} =
  if values.isNil or length < 2 or length > MaxInputLength.csize_t: return -1

  let initial = values[0]
  let stageCount = values[1]
  if initial < 0 or initial > 2 or stageCount < 1 or stageCount > MaxStageCount: return -1
  if length != (2 + 2 * stageCount).csize_t: return -1

  var result = initial
  for index in 0 ..< stageCount.int:
    let operation = values[2 + 2 * index]
    let argument = values[3 + 2 * index]
    if argument < 0 or argument > 2: return -1
    if operation == 0:
      result += argument
    elif operation == 1:
      result *= argument
    else:
      return -1
  result
