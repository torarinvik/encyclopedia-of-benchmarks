## Parse an ASCII base-2 integer, add three, and format with minimum width four.
const MaxTextLength = 128
const MaxMagnitude = 4_611_686_018_427_387_904'i64

proc isAsciiSpace(value: int64): bool =
  value == 32 or (value >= 9 and value <= 13)

proc isBinaryDigit(value: int64): bool =
  value == 48 or value == 49

proc binary_to_excess3*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "binary_to_excess3".} =
  if values == nil or length == 0 or length > MaxTextLength: return -1
  var start = csize_t(0)
  var finish = length
  while start < finish and isAsciiSpace(values[start]): inc start
  while finish > start and isAsciiSpace(values[finish - 1]): dec finish
  if start == finish: return -1

  var negative = false
  if values[start] == 43 or values[start] == 45:
    negative = values[start] == 45
    inc start
    if start == finish: return -1
  let prefixed = finish - start >= 2 and values[start] == 48 and
    (values[start + 1] == 98 or values[start + 1] == 66)
  if prefixed: start += 2
  if start == finish: return -1

  let digitStart = start
  var allowPrefixUnderscore = prefixed
  var haveDigit = false
  var lastWasDigit = false
  var magnitude = 0'i64
  var index = start
  while index < finish:
    let value = values[index]
    if isBinaryDigit(value):
      let digit = value - 48
      if magnitude > (MaxMagnitude - digit) div 2: return -1
      magnitude = magnitude * 2 + digit
      haveDigit = true
      lastWasDigit = true
      allowPrefixUnderscore = false
    elif value == ord('_').int64:
      if lastWasDigit and index + 1 < finish and isBinaryDigit(values[index + 1]):
        lastWasDigit = false
      elif allowPrefixUnderscore and not haveDigit and index == digitStart and
          index + 1 < finish and isBinaryDigit(values[index + 1]):
        allowPrefixUnderscore = false
      else:
        return -1
    else:
      return -1
    inc index
  if not haveDigit or not lastWasDigit: return -1

  var converted = magnitude
  if negative: converted = -converted
  converted += 3
  let resultIsNegative = converted < 0
  var remaining = if resultIsNegative: -converted else: converted
  var reversed: array[64, uint8]
  var digitCount = 0
  while true:
    reversed[digitCount] = uint8(ord('0') + int(remaining mod 2))
    inc digitCount
    remaining = remaining div 2
    if remaining == 0: break

  let signLength = if resultIsNegative: 1 else: 0
  var outputLength = signLength + digitCount
  if outputLength < 4: outputLength = 4
  if output == nil or outputCapacity < outputLength: return -2
  var position = 0
  let originalDigitCount = digitCount
  if resultIsNegative:
    output[position] = uint8(ord('-'))
    inc position
  let digitWidth = outputLength - signLength
  var pad = 0
  while pad < digitWidth - originalDigitCount:
    output[position] = uint8(ord('0'))
    inc position
    inc pad
  var reverseIndex = originalDigitCount
  while reverseIndex > 0:
    dec reverseIndex
    output[position] = reversed[reverseIndex]
    inc position
  int64(outputLength)
