## Return the English weekday name for a bounded ASCII d/m/yyyy date.
proc date_to_day*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "date_to_day".} =
  if input == nil or length < 9 or length > 11 or input[int(length) - 1] != 0: return -1
  let dateLength = int(length) - 1
  var cursor = 0
  var fields: array[3, int]
  for field in 0 .. 2:
    let start = cursor
    var value = 0
    while cursor < dateLength and input[cursor] >= 48 and input[cursor] <= 57:
      value = value * 10 + int(input[cursor] - 48)
      inc cursor
    let digits = cursor - start
    let maxDigits = if field == 2: 4 else: 2
    if digits < 1 or digits > maxDigits or (field == 2 and digits != 4): return -1
    fields[field] = value
    if field < 2:
      if cursor >= dateLength or input[cursor] != 47: return -1
      inc cursor
  if cursor != dateLength: return -1
  let day = fields[0]
  let month = fields[1]
  let year = fields[2]
  if year < 1 or year > 9999 or month < 1 or month > 12 or day < 1: return -1
  let leap = year mod 400 == 0 or (year mod 4 == 0 and year mod 100 != 0)
  var monthDays = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  if leap: monthDays[1] = 29
  if day > monthDays[month - 1]: return -1

  var adjustedYear = year
  var adjustedMonth = month
  if adjustedMonth < 3:
    dec adjustedYear
    adjustedMonth += 12
  let yearOfCentury = adjustedYear mod 100
  let century = adjustedYear div 100
  let weekday = (day + ((adjustedMonth + 1) * 26) div 10 + yearOfCentury +
    yearOfCentury div 4 + century div 4 + 5 * century) mod 7
  const names = ["Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
  let name = names[weekday]
  if outputCapacity < csize_t(name.len) or output == nil: return -2
  for index, byte in name:
    output[index] = uint8(ord(byte))
  int64(name.len)
