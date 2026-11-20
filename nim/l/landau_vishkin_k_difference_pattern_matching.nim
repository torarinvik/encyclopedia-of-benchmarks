const
  MaxPattern = 16
  MaxText = 32
  MaxErrors = 2
  MaxValidInput = 3 + MaxPattern + MaxText
  MaxParseableInput = MaxValidInput + 1
  Diagonals = MaxText + MaxErrors + 3
  Costs = MaxErrors + 2

proc landau_vishkin_k_difference_pattern_matching*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "landau_vishkin_k_difference_pattern_matching".} =
  if input.isNil or length < 3 or length > MaxParseableInput.csize_t: return -1
  let rawM = input[0]
  let rawN = input[1]
  let rawK = input[2]
  if rawM < 1 or rawM > MaxPattern.int64 or rawN < 0 or rawN > MaxText.int64 or
      rawK < 0 or rawK > MaxErrors.int64 or rawK >= rawM:
    return -1
  let m = rawM.int
  let n = rawN.int
  let k = rawK.int
  if length != (3 + m + n).csize_t: return -1
  for index in 0 ..< m:
    if input[3 + index] < 0 or input[3 + index] > 3: return -1
  for index in 0 ..< n:
    if input[3 + m + index] < 0 or input[3 + m + index] > 3: return -1
  if output.isNil or capacity < n.csize_t: return -2

  var frontier: array[Diagonals, array[Costs, int64]]
  for diagonal in 0 ..< Diagonals:
    for cost in 0 ..< Costs:
      frontier[diagonal][cost] = -1
  template slot(d: int): int = d + MaxErrors + 1
  for d in -(k + 1) .. -1:
    let magnitude = -d
    frontier[slot(d)][magnitude] = (magnitude - 1).int64
    frontier[slot(d)][magnitude - 1] = (magnitude - 2).int64

  var staged: array[MaxText, uint8]
  for errors in 0 .. k:
    for d in -errors .. n:
      let at = slot(d)
      var row = max(frontier[at][errors] + 1,
                    max(frontier[at - 1][errors], frontier[at + 1][errors] + 1))
      row = min(row, rawM)
      while row < rawM:
        let textIndex = row + d.int64
        if textIndex < 0 or textIndex >= rawN or
            input[3 + row.int] != input[3 + m + textIndex.int]:
          break
        inc row
      frontier[at][errors + 1] = row
      if row == rawM:
        let endpoint = d.int64 + rawM
        if endpoint >= 1 and endpoint <= rawN:
          staged[(endpoint - 1).int] = 1
  for index in 0 ..< n:
    output[index] = staged[index]
  n.int64
