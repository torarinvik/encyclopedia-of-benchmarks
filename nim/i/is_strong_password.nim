const MaxInput = 258

proc is_strong_password*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "is_strong_password".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let minimumLength = input[0]
  let textLengthValue = input[1]
  if minimumLength < 0 or minimumLength > 256 or textLengthValue < 0 or textLengthValue > 256: return -1
  let textLength = int(textLengthValue)
  if int(length) != textLength + 2: return -1

  var hasUppercase = false
  var hasLowercase = false
  var hasDigit = false
  var hasPunctuation = false
  for index in 0 ..< textLength:
    let value = input[index + 2]
    if value < 0 or value > 127: return -1
    if value >= 65 and value <= 90: hasUppercase = true
    if value >= 97 and value <= 122: hasLowercase = true
    if value >= 48 and value <= 57: hasDigit = true
    if (value >= 33 and value <= 47) or (value >= 58 and value <= 64) or
        (value >= 91 and value <= 96) or (value >= 123 and value <= 126): hasPunctuation = true

  if textLengthValue < minimumLength: return 0
  if hasUppercase and hasLowercase and hasDigit and hasPunctuation: 1 else: 0
