## Apply the pinned JavaScript title-case behavior to bounded ASCII words.
const MaxLength = 256

proc title_case_conversion*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "title_case_conversion".} =
  if length == 0 or length > csize_t(MaxLength + 1): return -1
  let declared = input[0]
  if declared < 0 or declared > MaxLength or length != csize_t(declared) + 1: return -1
  for index in 0 ..< int(declared):
    let value = input[index + 1]
    let letter = (value >= 65 and value <= 90) or (value >= 97 and value <= 122)
    if not letter and value != 32: return -1
    if value == 32 and (index == 0 or index + 1 == int(declared) or input[index] == 32): return -1
  if outputCapacity < csize_t(declared) + 1: return -2
  var atWordStart = true
  for index in 0 ..< int(declared):
    var value = input[index + 1]
    if value == 32:
      atWordStart = true
    elif atWordStart:
      if value >= 97 and value <= 122: value -= 32
      atWordStart = false
    elif value >= 65 and value <= 90:
      value += 32
    output[index] = uint8(value)
  output[int(declared)] = 0
  declared
