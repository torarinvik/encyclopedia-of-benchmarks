const MaxFaces = 8
const MaxDice = 8
const MaxTarget = 64

proc dice_throw*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "dice_throw".} =
  if values == nil or length != 3: return -1
  let facesValue = values[0]
  let diceValue = values[1]
  let targetValue = values[2]
  if facesValue < 1 or facesValue > MaxFaces or diceValue < 1 or diceValue > MaxDice or
      targetValue < 0 or targetValue > MaxTarget: return -1
  let faces = int(facesValue)
  let dice = int(diceValue)
  let target = int(targetValue)

  var table: array[MaxDice + 1, array[MaxTarget + 1, int64]]
  for total in 1 .. min(faces, target): table[1][total] = 1
  for die in 2 .. dice:
    for total in 1 .. target:
      for face in 1 .. min(total - 1, faces):
        table[die][total] += table[die - 1][total - face]
  table[dice][target]
