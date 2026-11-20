const MaxDraws = 256
const MaxInputLength = MaxDraws + 2

proc seven_sided_dice_from_five_sided_dice*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8],
    capacity: csize_t): int64 {.cdecl, exportc: "seven_sided_dice_from_five_sided_dice".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputLength): return -1
  let drawCountValue = input[0]
  if drawCountValue < 0 or drawCountValue > MaxDraws or
     length != csize_t(drawCountValue + 1): return -1
  let drawCount = int(drawCountValue)
  for index in 0 ..< drawCount:
    if input[index + 1] < 0 or input[index + 1] > 4: return -1

  var staged: array[MaxDraws, uint8]
  var written = 0
  var value = 0'i64
  var stateRange = 1'i64
  for index in 0 ..< drawCount:
    value = 5 * value + input[index + 1]
    stateRange *= 5
    while stateRange >= 7:
      let accepted = stateRange - stateRange mod 7
      if value < accepted:
        staged[written] = uint8(value mod 7 + 1)
        inc written
        value = value div 7
        stateRange = accepted div 7
      else:
        value -= accepted
        stateRange -= accepted

  if output.isNil or capacity < csize_t(written): return -2
  for index in 0 ..< written:
    output[index] = staged[index]
  int64(written)
