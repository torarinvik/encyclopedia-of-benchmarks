## Return the lowercase byte added to t by subtracting the two character sums.
const MaxStringLength = 4096
const MaxPackedLength = 8195

proc find_the_difference*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "find_the_difference".} =
  if input == nil or length < 2 or length > csize_t(MaxPackedLength): return -1
  if input[0] < 0 or input[0] > MaxStringLength or input[1] < 1 or input[1] > MaxStringLength + 1: return -1
  let sLength = int(input[0])
  let tLength = int(input[1])
  if tLength != sLength + 1 or int(length) != 2 + sLength + tLength: return -1
  var sumS = 0'i64
  var sumT = 0'i64
  for index in 0 ..< sLength:
    let value = input[2 + index]
    if value < 97 or value > 122: return -1
    sumS += value
  let tStart = 2 + sLength
  for index in 0 ..< tLength:
    let value = input[tStart + index]
    if value < 97 or value > 122: return -1
    sumT += value
  let difference = sumT - sumS
  if difference < 97 or difference > 122: return -1
  difference
