const MaxKeyLength = 256
const MaxPlaintextLength = 256
const MaxInputValues = 515

proc rc4*(input: ptr UncheckedArray[int64], length: csize_t,
          output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "rc4".} =
  if input == nil or length < 2 or length > csize_t(MaxInputValues): return -1
  let keyLengthValue = input[0]
  let plaintextLengthValue = input[1]
  if keyLengthValue < 1 or keyLengthValue > MaxKeyLength.int64: return -1
  if plaintextLengthValue < 0 or plaintextLengthValue > MaxPlaintextLength.int64: return -1
  let keyLength = int(keyLengthValue)
  let plaintextLength = int(plaintextLengthValue)
  if length != csize_t(2 + keyLength + plaintextLength): return -1
  for index in 0 ..< keyLength + plaintextLength:
    let value = input[2 + index]
    if value < 0 or value > 255: return -1
  if plaintextLength == 0: return 0
  if output == nil or capacity < csize_t(plaintextLength): return -2

  var state: array[256, uint8]
  for index in 0 ..< 256: state[index] = uint8(index)
  var j = 0
  for index in 0 ..< 256:
    j = (j + int(state[index]) + int(input[2 + index mod keyLength])) mod 256
    swap(state[index], state[j])

  var i = 0
  j = 0
  for offset in 0 ..< plaintextLength:
    i = (i + 1) mod 256
    j = (j + int(state[i])) mod 256
    swap(state[i], state[j])
    let streamIndex = (int(state[i]) + int(state[j])) mod 256
    output[offset] = uint8(input[2 + keyLength + offset]) xor state[streamIndex]
  int64(plaintextLength)
