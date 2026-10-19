## ARC4 port from Trimaran/enc-rc4, Copyright (C) 2001-2003 Christophe Devine.
## Distributed under GPL-2.0-or-later; see the package license notice.
type
  I64Input = ptr UncheckedArray[int64]
  ByteOutput = ptr UncheckedArray[uint8]
  ByteArray = ptr UncheckedArray[uint8]

const
  OutputBytes = 82
  MaxPasses = 2000
  KeyLengths: array[6, int] = [8, 8, 8, 4, 8, 4]
  DataLengths: array[6, int] = [8, 8, 8, 20, 28, 10]
  OutputOffsets: array[6, int] = [0, 8, 16, 24, 44, 72]

proc cryptOne(keys: ByteArray, keyBase, keyLength: int,
              staged: ByteArray, dataBase, dataLength: int) =
  var state: array[256, int]
  for index in 0 ..< 256: state[index] = index
  var j = 0
  for index in 0 ..< 256:
    j = (j + state[index] + int(keys[keyBase + index mod keyLength])) mod 256
    swap(state[index], state[j])
  var x = 0
  j = 0
  for offset in 0 ..< dataLength:
    x = (x + 1) mod 256
    let a = state[x]
    j = (j + a) mod 256
    let b = state[j]
    state[x] = b
    state[j] = a
    staged[dataBase + offset] = staged[dataBase + offset] xor uint8(state[(a + b) mod 256])

proc trimaran_enc_rc4*(input: I64Input, length: csize_t, output: ByteOutput,
                       outputCapacity: csize_t): int64 {.cdecl, exportc: "trimaran_enc_rc4".} =
  if input == nil or length != csize_t(1): return -1
  let passesValue = input[0]
  if passesValue < 1 or passesValue > MaxPasses.int64: return -1
  if output == nil or outputCapacity < csize_t(OutputBytes): return -2

  var keys: array[48, uint8]
  for index in 0 ..< 48: keys[index] = 0
  for index, value in [0x01'u8,0x23,0x45,0x67,0x89,0xab,0xcd,0xef]: keys[index] = value
  for index, value in [0x01'u8,0x23,0x45,0x67,0x89,0xab,0xcd,0xef]: keys[8 + index] = value
  for index, value in [0xef'u8,0x01,0x23,0x45]: keys[24 + index] = value
  for index, value in [0x01'u8,0x23,0x45,0x67,0x89,0xab,0xcd,0xef]: keys[32 + index] = value
  for index, value in [0xef'u8,0x01,0x23,0x45]: keys[40 + index] = value
  var plaintexts: array[168, uint8]
  for index in 0 ..< 168: plaintexts[index] = 0
  for index, value in [0x01'u8,0x23,0x45,0x67,0x89,0xab,0xcd,0xef]: plaintexts[index] = value
  for index, value in [0x12'u8,0x34,0x56,0x78,0x9a,0xbc,0xde,0xf0,
                       0x12,0x34,0x56,0x78,0x9a,0xbc,0xde,0xf0,
                       0x12,0x34,0x56,0x78,0x9a,0xbc,0xde,0xf0,
                       0x12,0x34,0x56,0x78]: plaintexts[112 + index] = value
  var staged: array[OutputBytes, uint8]
  let keysPtr = cast[ByteArray](addr keys[0])
  let plaintextPtr = cast[ByteArray](addr plaintexts[0])
  let stagedPtr = cast[ByteArray](addr staged[0])
  for vector in 0 ..< 6:
    let outputBase = OutputOffsets[vector]
    let inputBase = vector * 28
    for pass in 0 ..< int(passesValue):
      for byte in 0 ..< DataLengths[vector]: staged[outputBase + byte] = plaintexts[inputBase + byte]
      cryptOne(keysPtr, vector * 8, KeyLengths[vector], stagedPtr, outputBase, DataLengths[vector])
  for index in 0 ..< OutputBytes: output[index] = staged[index]
  int64(OutputBytes)
