## Emit the pinned default logarithmic-series expressions as ASCII lines.
proc decimalWidth(valueInput: int64): int =
  var value = valueInput
  result = 1
  while value >= 10:
    value = value div 10
    inc result

proc appendDecimal(output: ptr UncheckedArray[uint8], positionInput: int,
                   valueInput: int64): int =
  var value = valueInput
  var digits: array[20, uint8]
  var count = 0
  while true:
    digits[count] = uint8(value mod 10)
    inc count
    value = value div 10
    if value == 0: break
  result = positionInput
  while count > 0:
    dec count
    output[result] = uint8('0') + digits[count]
    inc result

proc hasNegativeSign(delta, term: int64): bool =
  (delta < 0 and term mod 2 == 1) or (delta >= 0 and term mod 2 == 0)

proc logarithmic_series*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "logarithmic_series".} =
  if values == nil or length != 2: return -1
  let xValue = values[0]
  let nTerms = values[1]
  if xValue < -10 or xValue > 10 or nTerms < -64 or nTerms > 256: return -1
  if nTerms <= 0: return 0
  let delta = xValue - 1
  let base = if delta < 0: -delta else: delta
  var needed = 0
  var term = 1'i64
  while term <= nTerms:
    needed += (if hasNegativeSign(delta, term): 2 else: 1) + decimalWidth(base) + 2 * decimalWidth(term) + 4
    inc term
  if output == nil or outputCapacity < csize_t(needed): return -2
  var position = 0
  term = 1
  while term <= nTerms:
    if hasNegativeSign(delta, term):
      output[position] = uint8('-'); inc position
    output[position] = uint8('('); inc position
    position = appendDecimal(output, position, base)
    output[position] = uint8('^'); inc position
    position = appendDecimal(output, position, term)
    output[position] = uint8(')'); inc position
    output[position] = uint8('/'); inc position
    position = appendDecimal(output, position, term)
    output[position] = uint8('\n'); inc position
    inc term
  int64(position)
