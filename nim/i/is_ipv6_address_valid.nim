const MaxInputLength = 256

type I64Input = ptr UncheckedArray[int64]

func isHexDigit(value: int64): bool =
  (value >= 48 and value <= 57) or (value >= 97 and value <= 102) or (value >= 65 and value <= 70)

func validIpv6Text(input: I64Input, textLength: int): bool =
  if textLength == 0: return false
  var groups = 0
  var groupLength = 0
  var compressionCount = 0
  var inGroup = false
  var index = 0
  while index < textLength:
    let value = input[index + 1]
    if value == 58:
      if index + 1 < textLength and input[index + 2] == 58:
        if (index > 0 and input[index] == 58) or
            (index + 2 < textLength and input[index + 3] == 58) or compressionCount != 0:
          return false
        if inGroup:
          inc groups
          inGroup = false
          groupLength = 0
        elif index != 0:
          return false
        inc compressionCount
        index += 2
        continue
      if index == 0 or index + 1 == textLength or not inGroup: return false
      inc groups
      inGroup = false
      groupLength = 0
      inc index
      continue
    if not isHexDigit(value) or groupLength == 4: return false
    inc groupLength
    inGroup = true
    inc index
  if inGroup: inc groups
  if compressionCount == 0: return groups == 8
  groups < 8

proc is_ipv6_address_valid*(input: I64Input, length: csize_t): int64 {.cdecl, exportc: "is_ipv6_address_valid".} =
  if input == nil or length < 1: return -1
  if input[0] < 0 or input[0] > MaxInputLength: return -1
  let textLength = int(input[0])
  if length != csize_t(textLength + 1): return -1
  for index in 0 ..< textLength:
    if input[index + 1] < 0 or input[index + 1] > 127: return -1
  if validIpv6Text(input, textLength): 1 else: 0
