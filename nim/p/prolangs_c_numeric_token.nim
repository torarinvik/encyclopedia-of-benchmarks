proc putI32(outp: ptr UncheckedArray[uint8], at: int, value: int32) =
  let bits = cast[uint32](value)
  for b in 0 ..< 4: outp[at + b] = uint8((bits shr (8 * b)) and 255)

proc prolangs_c_numeric_token*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if input == nil or length < 1 or length > 24: return -1
  let n = int(length)
  var text: array[24, uint8]
  for j in 0 ..< n:
    if input[j] < 32 or input[j] > 127: return -1
    text[j] = uint8(input[j])
  var i = 0
  var integer = 0'u32
  var hadInteger = false
  if text[i] >= 48 and text[i] <= 57:
    hadInteger = true
    while i < n and text[i] >= 48 and text[i] <= 57:
      let d = uint32(text[i] - 48); inc i
      if integer > (2147483647'u32 - d) div 10: return -1
      integer = integer * 10 + d
    if i == n:
      if capacity < 12 or output == nil: return -2
      putI32(output, 0, 256); putI32(output, 4, int32(integer)); putI32(output, 8, 0); return 12
  var fracDigits = 0'u32
  var fracCount = 0
  var leadingZeros = 0
  var hasDot = false
  if i < n and text[i] == 46:
    hasDot = true; inc i
    while i < n and text[i] == 48: inc leadingZeros; inc i
    if leadingZeros > 6: return -1
    while i < n and text[i] >= 48 and text[i] <= 57:
      if fracCount == 6: return -1
      fracDigits = fracDigits * 10 + uint32(text[i] - 48); inc fracCount; inc i
    if leadingZeros + fracCount > 6: return -1
  var value = 0'f32
  if fracCount != 0:
    value = float32(fracDigits)
    while value >= 1.0'f32: value /= 10.0'f32
    while leadingZeros > 0: value /= 10.0'f32; dec leadingZeros
  value += float32(integer)
  var hasExp = false
  if i < n and (text[i] == 101 or text[i] == 69):
    hasExp = true; inc i
    var sign = 1
    if i < n and (text[i] == 43 or text[i] == 45):
      if text[i] == 45: sign = -1
      inc i
    if i == n or text[i] < 48 or text[i] > 57: return -1
    var exponent = 0
    while i < n and text[i] >= 48 and text[i] <= 57:
      exponent = exponent * 10 + int(text[i] - 48); inc i
      if exponent > 6: return -1
    exponent *= sign
    while exponent > 0: value *= 10.0'f32; dec exponent
    while exponent < 0: value /= 10.0'f32; inc exponent
  if i != n or (not hasDot and not hasExp) or (not hadInteger and not hasDot): return -1
  if capacity < 12 or output == nil: return -2
  putI32(output, 0, 2001); putI32(output, 4, int32(integer)); putI32(output, 8, cast[int32](value)); 12
