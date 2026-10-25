## (c) William Landi 1991
## Permission to use this code is granted as long as the copyright
## notice remains in place.
##
## Clean-room bounded adaptation: numeric records replace the original text,
## temporary-file, listing, and object-file interfaces; two-pass SIC/XE symbol
## resolution and encoding are retained for the documented subset.

const MaxRecords = 16
const MaxLabels = 16
const Modulus = 1_000_000_007'i64

proc prolangs_c_assembler*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "prolangs_c_assembler".} =
  if input.isNil or length < 9 or length > 65: return -1
  if input[0] < 2 or input[0] > MaxRecords: return -1
  let count = int(input[0])
  if int(length) != 1 + count * 4: return -1
  var opcode, label, kind, operand, address, size: array[MaxRecords, int64]
  var code: array[MaxRecords, int64]
  var symbol: array[MaxLabels + 1, int64]
  var defined: array[MaxRecords + 1, bool]
  for i in 0 ..< count:
    let offset = 1 + i * 4
    if input[offset] < 0 or input[offset] > 11 or input[offset + 1] < 0 or input[offset + 1] > MaxLabels or
        input[offset + 2] < 0 or input[offset + 2] > 5 or input[offset + 3] < 0 or input[offset + 3] > 0xFFFFFF: return -1
    opcode[i] = input[offset]; label[i] = input[offset + 1]
    kind[i] = input[offset + 2]; operand[i] = input[offset + 3]
  if opcode[0] != 0 or opcode[count - 1] != 1 or label[0] == 0 or kind[0] != 0 or operand[0] > 0xFFFFF: return -1
  for i in 1 ..< count - 1:
    if opcode[i] == 0 or opcode[i] == 1: return -1
  if label[count - 1] != 0 or kind[count - 1] != 0 or operand[count - 1] != 0: return -1

  let startAddress = operand[0]
  var location = startAddress
  address[0] = location
  defined[int(label[0])] = true
  symbol[int(label[0])] = location
  for i in 0 ..< count:
    if i > 0:
      address[i] = location
      if label[i] != 0:
        let id = int(label[i])
        if defined[id] or location >= 0x100000: return -1
        defined[id] = true
        symbol[id] = location
    case opcode[i]
    of 0:
      if i != 0: return -1
      size[i] = 0
    of 1:
      if i != count - 1: return -1
      size[i] = 0
    of 2:
      if kind[i] != 0 or operand[i] > 256: return -1
      size[i] = operand[i]
    of 3:
      if kind[i] != 0 or operand[i] > 256: return -1
      size[i] = operand[i] * 3
    of 4:
      if kind[i] != 0: return -1
      size[i] = 3
    of 5, 6, 7, 8:
      if not ((kind[i] == 1 and operand[i] <= 4095) or
          ((kind[i] == 2 or kind[i] == 3) and operand[i] >= 1 and operand[i] <= MaxLabels)): return -1
      size[i] = 3
    of 9:
      if kind[i] != 0 or operand[i] != 0: return -1
      size[i] = 3
    of 10:
      if kind[i] != 4 or operand[i] > 5: return -1
      size[i] = 2
    of 11:
      if kind[i] != 5 or (operand[i] shr 4) > 5 or (operand[i] and 15) > 5: return -1
      size[i] = 2
    else: return -1
    if i > 0:
      if location > 0x100000 - size[i]: return -1
      location += size[i]

  let programLength = location - startAddress
  for i in 1 ..< count - 1:
    case opcode[i]
    of 4: code[i] = operand[i]
    of 5, 6, 7, 8:
      let base = (if opcode[i] == 5: 0 else: if opcode[i] == 6: 0x0C else: if opcode[i] == 7: 0x18 else: 0x3C)
      let ni = (if kind[i] == 1: 1 else: if kind[i] == 2: 3 else: 2)
      var field = operand[i]
      var pcRelative = 0'i64
      if kind[i] == 2 or kind[i] == 3:
        let id = int(operand[i])
        if not defined[id]: return -1
        field = symbol[id] - (address[i] + 3)
        if field < -2048 or field > 2047: return -1
        pcRelative = 1
        field = field and 0xFFF
      code[i] = (base or ni) * 65536 + pcRelative * 8192 + field
    of 9: code[i] = 0x4F0000
    of 10: code[i] = 0xB400 or (operand[i] shl 4)
    of 11: code[i] = 0x9000 or operand[i]
    else: discard
  var checksum = (programLength * 257 + startAddress * 17) mod Modulus
  for i in 0 ..< count:
    checksum = (checksum * 131 + (address[i] + 1) * 17 + code[i] * 3 + size[i]) mod Modulus
  checksum
