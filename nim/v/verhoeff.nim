type I64Input = ptr UncheckedArray[int64]

const D: array[100, uint8] = [
  0'u8,1,2,3,4,5,6,7,8,9, 1,2,3,4,0,6,7,8,9,5,
  2,3,4,0,1,7,8,9,5,6, 3,4,0,1,2,8,9,5,6,7,
  4,0,1,2,3,9,5,6,7,8, 5,9,8,7,6,0,4,3,2,1,
  6,5,9,8,7,1,0,4,3,2, 7,6,5,9,8,2,1,0,4,3,
  8,7,6,5,9,3,2,1,0,4, 9,8,7,6,5,4,3,2,1,0]
const P: array[80, uint8] = [
  0'u8,1,2,3,4,5,6,7,8,9, 1,5,7,6,2,8,3,0,9,4,
  5,8,0,3,7,9,6,1,4,2, 8,9,1,6,0,4,3,5,2,7,
  9,4,5,3,1,2,6,8,7,0, 4,2,8,6,5,7,3,9,0,1,
  2,7,9,3,8,0,6,4,1,5, 7,0,4,6,9,1,3,2,5,8]

proc verhoeff*(digits: I64Input, length: csize_t): int64 {.cdecl, exportc: "verhoeff".} =
  if length == 0 or length > 1024: return -1
  var i = csize_t(0)
  while i < length:
    if digits[i] < 0'i64 or digits[i] > 9'i64: return -1
    inc i
  var checksum = 0
  i = 0
  while i < length:
    let digit = int(digits[length - i - 1])
    let permutation = int(P[int(i mod 8) * 10 + digit])
    checksum = int(D[checksum * 10 + permutation])
    inc i
  if checksum == 0: 1 else: 0
