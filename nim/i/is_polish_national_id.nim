type I64Input = ptr UncheckedArray[int64]

proc is_polish_national_id*(input: I64Input, length: csize_t): int64
    {.cdecl, exportc: "is_polish_national_id".} =
  if input == nil or length != 11: return -1
  var number = 0'i64
  for index in 0 ..< 11:
    if input[index] < 48 or input[index] > 57: return -1
    number = number * 10 + input[index] - 48
  if number < 10_100_000'i64 or number > 99_923_199_999'i64: return 0
  let month = (input[2] - 48) * 10 + input[3] - 48
  let validMonth = (month >= 1 and month <= 12) or (month >= 21 and month <= 32) or
    (month >= 41 and month <= 52) or (month >= 61 and month <= 72) or (month >= 81 and month <= 92)
  if not validMonth: return 0
  let day = (input[4] - 48) * 10 + input[5] - 48
  if day < 1 or day > 31: return 0
  let weights = [1'i64, 3'i64, 7'i64, 9'i64]
  var subtotal = 0'i64
  for index in 0 ..< 10:
    subtotal += ((input[index] - 48) * weights[index mod 4]) mod 10
  let checksum = 10 - subtotal mod 10
  if checksum == number mod 10: 1 else: 0
