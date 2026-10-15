## Find the first shared node identity by switching traversal heads.
const MaxListLength = 1024
const MaxInputLength = 2 + 2 * MaxListLength

proc intersection_of_two_linked_lists*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "intersection_of_two_linked_lists".} =
  if length < 2 or length > csize_t(MaxInputLength): return -2
  let firstLengthValue = input[0]
  let secondLengthValue = input[1]
  if firstLengthValue < 0 or firstLengthValue > MaxListLength or
      secondLengthValue < 0 or secondLengthValue > MaxListLength: return -2
  let firstLength = int(firstLengthValue)
  let secondLength = int(secondLengthValue)
  if int(length) != 2 + firstLength + secondLength: return -2
  for index in 2 ..< int(length):
    if input[index] < 0 or input[index] > 2147483647'i64: return -2
  if firstLength == 0 or secondLength == 0: return -1

  var firstPosition = 0
  var secondPosition = 0
  var firstOnFirstList = true
  var secondOnFirstList = false
  for _ in 0 ..< firstLength + secondLength + 1:
    let firstBase = if firstOnFirstList: 2 else: 2 + firstLength
    let firstSourceLength = if firstOnFirstList: firstLength else: secondLength
    let secondBase = if secondOnFirstList: 2 else: 2 + firstLength
    let secondSourceLength = if secondOnFirstList: firstLength else: secondLength
    let firstNode = input[firstBase + firstPosition]
    let secondNode = input[secondBase + secondPosition]
    if firstNode == secondNode: return firstNode
    inc firstPosition
    inc secondPosition
    let firstIsNull = firstPosition == firstSourceLength
    let secondIsNull = secondPosition == secondSourceLength
    if firstIsNull and secondIsNull: return -1
    if firstIsNull:
      firstOnFirstList = not firstOnFirstList
      firstPosition = 0
    if secondIsNull:
      secondOnFirstList = not secondOnFirstList
      secondPosition = 0
  -1
