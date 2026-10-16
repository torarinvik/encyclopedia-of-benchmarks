const MaxTextLength = 41
const MaxParseableLength = 43
const ColorNames: array[12, string] = [
  "Black", "Brown", "Red", "Orange", "Yellow", "Green",
  "Blue", "Violet", "Grey", "White", "Gold", "Silver"
]

proc colorCode(values: ptr UncheckedArray[int64], start, finish: int): int =
  for color, name in ColorNames:
    if finish - start != name.len: continue
    var same = true
    for i in 0 ..< name.len:
      if values[start + i + 1] != int64(ord(name[i])): same = false
    if same: return color
  -1

proc appendByte(buffer: var array[64, uint8], length: var int, value: int) =
  buffer[length] = uint8(value)
  inc length

proc appendText(buffer: var array[64, uint8], length: var int, text: string) =
  for ch in text: appendByte(buffer, length, ord(ch))

proc appendUInt(buffer: var array[64, uint8], length: var int, value: uint64) =
  var digits: array[24, uint8]
  var count = 0
  var remaining = value
  while true:
    digits[count] = uint8(ord('0') + int(remaining mod 10))
    inc count
    remaining = remaining div 10
    if remaining == 0: break
  while count > 0:
    dec count
    buffer[length] = digits[count]
    inc length

proc toleranceAllowed(color: int): bool =
  (color >= 1 and color <= 8) or color == 10 or color == 11

proc resistor_color_code*(values: ptr UncheckedArray[int64], length: csize_t,
                          output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "resistor_color_code".} =
  if values.isNil or length < 2 or length > MaxParseableLength: return -1
  let textLength = values[0]
  if textLength < 1 or textLength > MaxTextLength or length != csize_t(textLength + 1): return -1
  for i in 0 ..< int(textLength):
    if values[i + 1] < 0 or values[i + 1] > 127: return -1

  var colors: array[6, int]
  var colorCount = 0
  var start = 0
  for i in 0 .. int(textLength):
    if i == int(textLength) or values[i + 1] == ord(','):
      if colorCount == colors.len or i == start: return -1
      let color = colorCode(values, start, i)
      if color < 0: return -1
      colors[colorCount] = color
      inc colorCount
      start = i + 1
  if colorCount < 3 or colorCount > 6: return -1

  let significantCount = if colorCount <= 4: 2 else: 3
  var significant = 0'u64
  for i in 0 ..< significantCount:
    if colors[i] > 9: return -1
    significant = significant * 10 + uint64(colors[i])
  let multiplier = colors[significantCount]
  let toleranceColor = if colorCount >= 4: colors[significantCount + 1] else: -1
  let temperatureColor = if colorCount == 6: colors[5] else: -1
  if toleranceColor >= 0 and not toleranceAllowed(toleranceColor): return -1
  if temperatureColor > 8: return -1

  var buffer: array[64, uint8]
  var outLength = 0
  if multiplier <= 9:
    var resistance = significant
    for _ in 0 ..< multiplier: resistance *= 10
    appendUInt(buffer, outLength, resistance)
  elif multiplier == 10:
    appendUInt(buffer, outLength, significant div 10)
    appendByte(buffer, outLength, ord('.'))
    appendByte(buffer, outLength, ord('0') + int(significant mod 10))
  else:
    let whole = significant div 100
    let fraction = int(significant mod 100)
    appendUInt(buffer, outLength, whole)
    appendByte(buffer, outLength, ord('.'))
    if fraction == 0: appendByte(buffer, outLength, ord('0'))
    elif fraction mod 10 == 0: appendByte(buffer, outLength, ord('0') + fraction div 10)
    else:
      appendByte(buffer, outLength, ord('0') + fraction div 10)
      appendByte(buffer, outLength, ord('0') + fraction mod 10)
  appendByte(buffer, outLength, 0xCE); appendByte(buffer, outLength, 0xA9)
  appendByte(buffer, outLength, ord(' ')); appendByte(buffer, outLength, 0xC2); appendByte(buffer, outLength, 0xB1)
  const ToleranceText: array[12, string] = ["", "1", "2", "0.05", "0.02", "0.5", "0.25", "0.1", "0.01", "", "5", "10"]
  appendText(buffer, outLength, if toleranceColor < 0: "20" else: ToleranceText[toleranceColor])
  appendText(buffer, outLength, "% ")
  if temperatureColor >= 0:
    const TemperatureValues: array[9, uint64] = [250'u64, 100, 50, 15, 25, 20, 10, 5, 1]
    appendUInt(buffer, outLength, TemperatureValues[temperatureColor])
    appendText(buffer, outLength, " ppm/K")
  if capacity < csize_t(outLength) or (output.isNil and outLength > 0): return -2
  for i in 0 ..< outLength: output[i] = buffer[i]
  int64(outLength)
