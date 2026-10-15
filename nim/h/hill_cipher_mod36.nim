proc symbolValue(value: int64): int =
  var code = value
  if code >= ord('a') and code <= ord('z'): code -= ord('a') - ord('A')
  if code >= ord('A') and code <= ord('Z'): return int(code - ord('A'))
  if code >= ord('0') and code <= ord('9'): return int(code - ord('0')) + 26
  -1

proc outputSymbol(value: int): uint8 =
  if value < 26: uint8(ord('A') + value) else: uint8(ord('0') + value - 26)

proc hill_cipher_mod36*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "hill_cipher_mod36".} =
  if input.isNil or length < 3 or input[0] < 0 or input[0] > 1: return -1
  let rawLength = input[1]
  if rawLength < 1 or rawLength > 256 or length != csize_t(rawLength + 2): return -1
  var text: array[256, int]
  var count = 0
  for i in 0..<int(rawLength):
    let byte = input[2+i]
    if byte < 0 or byte > 127: return -1
    let value = symbolValue(byte)
    if value >= 0: text[count] = value; inc count
  if count == 0: return -1
  if count mod 2 != 0: text[count] = text[count-1]; inc count
  if output.isNil or capacity < csize_t(count): return -2
  let decrypt = input[0] == 1
  for i in countup(0, count-1, 2):
    let a = text[i]; let b = text[i+1]
    let first = if decrypt: (6*a + 25*b) mod 36 else: (2*a + 5*b) mod 36
    let second = if decrypt: (5*a + 26*b) mod 36 else: (a + 6*b) mod 36
    output[i] = outputSymbol(first)
    output[i+1] = outputSymbol(second)
  int64(count)
