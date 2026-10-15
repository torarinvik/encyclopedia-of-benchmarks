proc getCheckDigit(barcodeIn: int64): int64 =
  var barcode = barcodeIn div 10
  var checker = false
  var total: int64 = 0
  while barcode != 0:
    let multiplier: int64 = if checker: 1 else: 3
    total += multiplier * (barcode mod 10)
    barcode = barcode div 10
    checker = not checker
  (10 - total mod 10) mod 10

proc decimalLength(valueIn: int64): int =
  var value = valueIn
  result = 1
  while value >= 10:
    value = value div 10
    inc result

proc barcode_validator*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "barcode_validator".} =
  if values == nil or length != 2 or values[0] < 0 or values[0] > 1 or values[1] < 0:
    return -1
  let operation = values[0]
  let barcode = values[1]
  if operation == 0: return getCheckDigit(barcode)
  if decimalLength(barcode) == 13 and getCheckDigit(barcode) == barcode mod 10:
    return 1
  0
