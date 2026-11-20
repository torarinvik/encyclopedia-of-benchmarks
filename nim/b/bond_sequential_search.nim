const MaxN = 64
const MaxValue = 255'i64
const AbsentCode = 64'i64
const PackBase = 65'i64

proc bond_sequential_search*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "bond_sequential_search".} =
  if input == nil or length < 3 or length > csize_t(MaxN + 4): return -1
  let countValue = input[0]
  let keyA = input[1]
  let keyB = input[2]
  if countValue < 0 or countValue > MaxN or length != csize_t(countValue + 3): return -1
  if keyA < 0 or keyA > MaxValue or keyB < 0 or keyB > MaxValue or keyA == keyB: return -1

  let count = int(countValue)
  for i in 0 ..< count:
    let value = input[i + 3]
    if value < 0 or value > MaxValue: return -1

  var indexA = AbsentCode
  var indexB = AbsentCode
  let composite = keyA or keyB
  for i in 0 ..< count:
    if indexA != AbsentCode and indexB != AbsentCode: break
    let value = input[i + 3]
    if (value and composite) != value: continue
    if indexA == AbsentCode and value == keyA: indexA = int64(i)
    if indexB == AbsentCode and value == keyB: indexB = int64(i)
  return indexA * PackBase + indexB
