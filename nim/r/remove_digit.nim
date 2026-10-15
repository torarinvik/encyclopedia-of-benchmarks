const InvalidResult = -1'i64
const MinValidInput = -9_223_372_036_854_775_807'i64

proc remove_digit*(value: int64): int64 {.cdecl, exportc: "remove_digit".} =
  if value < MinValidInput: return InvalidResult
  let magnitude = if value < 0: -value else: value
  if magnitude < 10: return InvalidResult

  var topPlace = 1'i64
  while topPlace <= magnitude div 10: topPlace *= 10
  var digitCount = 0'i64
  var place = topPlace
  while place > 0:
    inc digitCount
    place = place div 10
  var maximum = 0'i64
  for removed in 0'i64 ..< digitCount:
    var candidate = 0'i64
    var position = 0'i64
    place = topPlace
    while place > 0:
      let digit = (magnitude div place) mod 10
      if position != removed: candidate = candidate * 10 + digit
      inc position
      place = place div 10
    if candidate > maximum: maximum = candidate
  maximum
