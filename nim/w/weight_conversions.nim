## Preserve the six integer weight-conversion strings from the pinned Ruby source.
const MaxAmount = 1_000_000

proc appendText(buffer: var array[64, uint8], position: var int, text: string) =
  for character in text:
    buffer[position] = uint8(ord(character))
    inc position

proc appendI64(buffer: var array[64, uint8], position: var int, value: int64) =
  var digits: array[24, uint8]
  var count = 0
  var magnitude = value
  if magnitude < 0:
    buffer[position] = uint8(ord('-'))
    inc position
    magnitude = -magnitude
  while true:
    digits[count] = uint8(ord('0')) + uint8(magnitude mod 10)
    inc count
    magnitude = magnitude div 10
    if magnitude == 0: break
  while count > 0:
    dec count
    buffer[position] = digits[count]
    inc position

proc appendFixed(buffer: var array[64, uint8], position: var int, value: float64) =
  let scaled = value * 100.0
  var cents = if scaled < 0.0: -int64(-scaled + 0.5) else: int64(scaled + 0.5)
  if value > 0.0 and (float64(cents) + 0.5) / 100.0 <= value: inc cents
  elif value < 0.0 and (float64(cents) - 0.5) / 100.0 >= value: dec cents
  if cents < 0:
    buffer[position] = uint8(ord('-'))
    inc position
    cents = -cents
  appendI64(buffer, position, cents div 100)
  let fraction = cents mod 100
  buffer[position] = uint8(ord('.'))
  inc position
  if fraction == 0:
    buffer[position] = uint8(ord('0'))
    inc position
  elif fraction mod 10 == 0:
    buffer[position] = uint8(ord('0')) + uint8(fraction div 10)
    inc position
  else:
    buffer[position] = uint8(ord('0')) + uint8(fraction div 10)
    buffer[position + 1] = uint8(ord('0')) + uint8(fraction mod 10)
    position += 2

proc weight_conversions*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "weight_conversions".} =
  if input.isNil or length != 2: return -1
  let operation = input[0]
  let amount = input[1]
  if operation < 0 or operation > 5 or amount < -MaxAmount or amount > MaxAmount: return -1
  var buffer: array[64, uint8]
  var position = 0
  var converted: int64 = 0
  case operation
  of 0:
    appendI64(buffer, position, amount)
    appendText(buffer, position, " kg = ")
    appendI64(buffer, position, amount * 1000)
    appendText(buffer, position, " g")
  of 1:
    converted = if amount >= 0: amount div 1000 else: -((-amount + 999) div 1000)
    appendI64(buffer, position, amount)
    appendText(buffer, position, " g = ")
    appendI64(buffer, position, converted)
    appendText(buffer, position, " kg")
  of 2:
    appendI64(buffer, position, amount)
    appendText(buffer, position, " lb = ")
    appendI64(buffer, position, amount * 16)
    appendText(buffer, position, " oz")
  of 3:
    converted = if amount >= 0: amount div 16 else: -((-amount + 15) div 16)
    appendI64(buffer, position, amount)
    appendText(buffer, position, " oz = ")
    appendI64(buffer, position, converted)
    appendText(buffer, position, " lb")
  of 4:
    appendI64(buffer, position, amount)
    appendText(buffer, position, " kg = ")
    appendFixed(buffer, position, float64(amount) * 2.205)
    appendText(buffer, position, " lb")
  of 5:
    appendI64(buffer, position, amount)
    appendText(buffer, position, " lb = ")
    appendFixed(buffer, position, float64(amount) / 2.205)
    appendText(buffer, position, " kg")
  else:
    return -1
  buffer[position] = 0
  if outputCapacity < csize_t(position + 1) or output.isNil: return -2
  for index in 0 .. position:
    output[index] = buffer[index]
  int64(position)
