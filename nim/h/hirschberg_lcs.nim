const MaxSequenceLength = 64
const MaxInputLength = 132

type HirschbergState = object
  forward: array[MaxSequenceLength + 1, int32]
  backward: array[MaxSequenceLength + 1, int32]
  result: array[MaxSequenceLength, uint8]
  resultLength: int

proc lcsRow(input: ptr UncheckedArray[int64], aBase, a0, a1, bBase, b0, b1: int,
            reverseA, reverseB: bool, row: var array[MaxSequenceLength + 1, int32]) =
  let width = b1 - b0
  for j in 0 .. width: row[j] = 0
  for i in 0 ..< a1 - a0:
    let av = input[aBase + (if reverseA: a1 - 1 - i else: a0 + i)]
    var diagonal = 0'i32
    for j in 1 .. width:
      let above = row[j]
      let bv = input[bBase + (if reverseB: b1 - j else: b0 + j - 1)]
      if av == bv: row[j] = diagonal + 1
      elif row[j - 1] > row[j]: row[j] = row[j - 1]
      diagonal = above

proc recoverLcs(input: ptr UncheckedArray[int64], aBase, a0, a1, bBase, b0, b1: int,
                state: var HirschbergState) =
  let aLength = a1 - a0
  let bLength = b1 - b0
  if aLength == 0 or bLength == 0: return
  if aLength == 1:
    let target = input[aBase + a0]
    for j in b0 ..< b1:
      if input[bBase + j] == target:
        state.result[state.resultLength] = uint8(target)
        inc state.resultLength
        return
    return

  let middle = a0 + aLength div 2
  lcsRow(input, aBase, a0, middle, bBase, b0, b1, false, false, state.forward)
  lcsRow(input, aBase, middle, a1, bBase, b0, b1, true, true, state.backward)
  var split = 0
  var bestScore = -1'i32
  for j in 0 .. bLength:
    let score = state.forward[j] + state.backward[bLength - j]
    if score > bestScore:
      bestScore = score
      split = j
  recoverLcs(input, aBase, a0, middle, bBase, b0, b0 + split, state)
  recoverLcs(input, aBase, middle, a1, bBase, b0 + split, b1, state)

proc hirschberg_lcs*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "hirschberg_lcs".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  if input[0] < 0 or input[0] > MaxSequenceLength or input[1] < 0 or input[1] > MaxSequenceLength: return -1
  let firstLength = int(input[0])
  let secondLength = int(input[1])
  if length != csize_t(2 + firstLength + secondLength): return -1
  for i in 0 ..< firstLength + secondLength:
    if input[2 + i] < 0 or input[2 + i] > 127: return -1

  var state: HirschbergState
  let aBase = if firstLength < secondLength: 2 + firstLength else: 2
  let bBase = if firstLength < secondLength: 2 else: 2 + firstLength
  let aLength = max(firstLength, secondLength)
  let bLength = min(firstLength, secondLength)
  recoverLcs(input, aBase, 0, aLength, bBase, 0, bLength, state)
  if output == nil or capacity < csize_t(state.resultLength): return -2
  for i in 0 ..< state.resultLength: output[i] = state.result[i]
  int64(state.resultLength)
