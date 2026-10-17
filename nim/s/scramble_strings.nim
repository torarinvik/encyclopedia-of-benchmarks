const MaxLength = 8
const MaxParseableInputLength = 2 * MaxLength + 3
const MemoSize = 9 * 9 * 9

proc scrambleRec(values: ptr UncheckedArray[int64], base1, base2, start1, start2, span: int,
                 memo: var array[MemoSize, int64]): int64 =
  let slot = (start1 * 9 + start2) * 9 + span
  if memo[slot] >= 0: return memo[slot]

  var same = true
  for offset in 0 ..< span:
    if values[base1 + start1 + offset] != values[base2 + start2 + offset]:
      same = false
      break
  if same:
    memo[slot] = 1
    return 1

  var counts: array[26, int]
  for offset in 0 ..< span:
    inc counts[int(values[base1 + start1 + offset] - 97)]
    dec counts[int(values[base2 + start2 + offset] - 97)]
  for count in counts:
    if count != 0:
      memo[slot] = 0
      return 0

  for split in 1 ..< span:
    if scrambleRec(values, base1, base2, start1, start2, split, memo) != 0 and
        scrambleRec(values, base1, base2, start1 + split, start2 + split, span - split, memo) != 0:
      memo[slot] = 1
      return 1
    if scrambleRec(values, base1, base2, start1, start2 + span - split, split, memo) != 0 and
        scrambleRec(values, base1, base2, start1 + split, start2, span - split, memo) != 0:
      memo[slot] = 1
      return 1
  memo[slot] = 0
  0

proc scramble_strings*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "scramble_strings".} =
  if values.isNil or length < 1 or length > MaxParseableInputLength.csize_t: return -1
  let nValue = values[0]
  if nValue < 0 or nValue > MaxLength: return -1
  let n = int(nValue)
  if length.int != 2 * n + 1: return -1
  for index in 1 ..< length.int:
    if values[index] < 97 or values[index] > 122: return -1

  var memo: array[MemoSize, int64]
  for index in 0 ..< MemoSize: memo[index] = -1
  scrambleRec(values, 1, 1 + n, 0, 0, n, memo)
