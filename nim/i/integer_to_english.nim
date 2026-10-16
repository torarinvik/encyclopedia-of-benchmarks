const SmallWords: array[21, string] = [
  "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
  "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen",
  "Seventeen", "Eighteen", "Nineteen", "Twenty"
]
const TensWords: array[10, string] = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"]
const ScaleWords: array[4, string] = ["", "Thousand", "Million", "Billion"]

proc appendText(buffer: var array[128, uint8], position: var int, text: string) =
  for character in text:
    buffer[position] = uint8(ord(character))
    inc position

proc appendWord(buffer: var array[128, uint8], position: var int, text: string) =
  if position != 0:
    buffer[position] = uint8(ord(' '))
    inc position
  appendText(buffer, position, text)

proc appendGroup(buffer: var array[128, uint8], position: var int, valueInput: int) =
  var value = valueInput
  if value >= 100:
    appendWord(buffer, position, SmallWords[value div 100])
    appendWord(buffer, position, "Hundred")
    value = value mod 100
  if value <= 20:
    if value != 0: appendWord(buffer, position, SmallWords[value])
  elif value mod 10 == 0:
    appendWord(buffer, position, TensWords[value div 10])
  else:
    appendWord(buffer, position, TensWords[value div 10])
    appendWord(buffer, position, SmallWords[value mod 10])

proc integer_to_english*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "integer_to_english".} =
  if input.isNil or length != 1 or input[0] < -2_147_483_648'i64 or input[0] > 2_147_483_647'i64: return -1
  var buffer: array[128, uint8]
  var position = 0
  let value = input[0]
  if value == 0:
    appendWord(buffer, position, "Zero")
  elif value > 0:
    var groups: array[4, int]
    var remaining = int(value)
    var count = 0
    while remaining != 0:
      groups[count] = remaining mod 1000
      inc count
      remaining = remaining div 1000
    while count > 0:
      dec count
      if groups[count] != 0:
        appendGroup(buffer, position, groups[count])
        if count != 0: appendWord(buffer, position, ScaleWords[count])
  if position > int(outputCapacity) or (position != 0 and output.isNil): return -2
  for index in 0 ..< position: output[index] = buffer[index]
  int64(position)
