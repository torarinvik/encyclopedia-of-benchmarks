const MaxNames = 6000
const MaxNameLength = 19
const MaxInputLength = 100001

proc compareNames(input: ptr UncheckedArray[int64], offsets, nameLengths: ptr UncheckedArray[int], first, second: int): int =
  let firstLength = nameLengths[first]
  let secondLength = nameLengths[second]
  let sharedLength = min(firstLength, secondLength)
  for index in 0 ..< sharedLength:
    let firstLetter = input[offsets[first] + index]
    let secondLetter = input[offsets[second] + index]
    if firstLetter < secondLetter: return -1
    if firstLetter > secondLetter: return 1
  if firstLength < secondLength: return -1
  if firstLength > secondLength: return 1
  0

proc problem22*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "problem22".} =
  if input == nil or length < 1 or length > MaxInputLength.csize_t: return -1
  let rawCount = input[0]
  if rawCount < 0 or rawCount > MaxNames.int64: return -1
  let count = rawCount.int
  var offsets: array[MaxNames, int]
  var nameLengths: array[MaxNames, int]
  var order: array[MaxNames, int]
  var cursor = 1
  for name in 0 ..< count:
    if cursor >= length.int: return -1
    let rawNameLength = input[cursor]
    cursor += 1
    if rawNameLength < 1 or rawNameLength > MaxNameLength.int64: return -1
    let nameLength = rawNameLength.int
    if nameLength > length.int - cursor: return -1
    offsets[name] = cursor
    nameLengths[name] = nameLength
    for letter in 0 ..< nameLength:
      let value = input[cursor + letter]
      if value < 1 or value > 26: return -1
    cursor += nameLength
    order[name] = name
  if cursor != length.int: return -1

  let gaps = [701, 301, 132, 57, 23, 10, 4, 1]
  for gap in gaps:
    if gap >= count: continue
    for index in gap ..< count:
      let key = order[index]
      var position = index
      while position >= gap and compareNames(input, cast[ptr UncheckedArray[int]](addr offsets[0]),
          cast[ptr UncheckedArray[int]](addr nameLengths[0]), order[position - gap], key) > 0:
        order[position] = order[position - gap]
        position -= gap
      order[position] = key

  var total = 0'i64
  for position in 0 ..< count:
    let name = order[position]
    var score = 0'i64
    for letter in 0 ..< nameLengths[name]:
      score += input[offsets[name] + letter]
    total += (position + 1).int64 * score
  total
