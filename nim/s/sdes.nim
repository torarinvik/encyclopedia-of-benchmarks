const
  P8: array[8, uint8] = [6'u8, 3, 7, 4, 8, 5, 10, 9]
  P10: array[10, uint8] = [3'u8, 5, 2, 7, 4, 10, 1, 9, 8, 6]
  P4: array[4, uint8] = [2'u8, 4, 3, 1]
  IP: array[8, uint8] = [2'u8, 6, 3, 1, 4, 8, 5, 7]
  IPInverse: array[8, uint8] = [4'u8, 1, 3, 5, 7, 2, 8, 6]
  Expansion: array[8, uint8] = [4'u8, 1, 2, 3, 2, 3, 4, 1]
  Sboxes: array[32, uint8] = [1'u8, 0, 3, 2, 3, 2, 1, 0, 0, 2, 1, 3, 3, 1, 3, 2,
    0, 1, 2, 3, 2, 0, 1, 3, 3, 0, 1, 0, 2, 1, 0, 3]

proc tableValue(table, index: int): uint32 =
  case table
  of 0: uint32(P8[index])
  of 1: uint32(P10[index])
  of 2: uint32(IP[index])
  of 3: uint32(IPInverse[index])
  of 4: uint32(Expansion[index])
  else: uint32(P4[index])

proc permute(value: uint32, inputBits: int, table: int, count: int): uint32 =
  var result = 0'u32
  for index in 0 ..< count:
    let position = tableValue(table, index)
    result = (result shl 1) or ((value shr (uint32(inputBits) - position)) and 1'u32)
  result

proc rotate5(value: uint32, amount: uint32): uint32 =
  ((value shl amount) or (value shr (5'u32 - amount))) and 31'u32

proc subkey(key: uint32, round: uint32): uint32 =
  let selected = permute(key, 10, 1, 10)
  var left = selected shr 5
  var right = selected and 31'u32
  left = rotate5(left, 1)
  right = rotate5(right, 1)
  if round != 0:
    left = rotate5(left, 2)
    right = rotate5(right, 2)
  permute((left shl 5) or right, 10, 0, 8)

proc sboxValue(box: int, nibble: uint32): uint32 =
  let row = int(((nibble and 8'u32) shr 2) or (nibble and 1'u32))
  let column = int((nibble shr 1) and 3'u32)
  uint32(Sboxes[box * 16 + row * 4 + column])

proc fk(state: uint32, key: uint32): uint32 =
  let left = state shr 4
  let right = state and 15'u32
  let mixed = permute(right, 4, 4, 8) xor key
  let substituted = (sboxValue(0, mixed shr 4) shl 2) or sboxValue(1, mixed and 15'u32)
  ((left xor permute(substituted, 4, 5, 4)) shl 4) or right

proc crypt(message: uint32, key: uint32, decrypt: bool): uint32 =
  let first = subkey(key, 0)
  let second = subkey(key, 1)
  var state = permute(message, 8, 2, 8)
  state = fk(state, if decrypt: second else: first)
  state = ((state and 15'u32) shl 4) or (state shr 4)
  state = fk(state, if decrypt: first else: second)
  permute(state, 8, 3, 8)

## Return ciphertext and the plaintext recovered with the reversed subkeys.
proc sdes*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "sdes".} =
  if input == nil or length != 2: return -1
  if input[0] < 0 or input[0] > 1023 or input[1] < 0 or input[1] > 255: return -1
  if output == nil or outputCapacity < 2: return -2
  let key = uint32(input[0])
  let ciphertext = crypt(uint32(input[1]), key, false)
  let recovered = crypt(ciphertext, key, true)
  output[0] = uint8(ciphertext)
  output[1] = uint8(recovered)
  2
