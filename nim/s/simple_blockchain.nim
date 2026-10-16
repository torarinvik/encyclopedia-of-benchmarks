include "sha256.nim"

const MaxValues = 465
const MaxChain = 8
const MaxData = 64
const MaxHeader = 160
const NonceAttempts = 4096
const MaxOutput = 728

type Block = object
  timestampSec: int64
  data: array[MaxData, uint8]
  dataLength: int
  previousHash: array[64, uint8]
  previousHashLength: int
  nonce: int64
  hash: array[64, uint8]

proc appendDecimal(buffer: var array[MaxHeader, int64], positionValue: int,
                   valueValue: int64): int =
  var digits: array[20, int64]
  var count = 0
  var value = valueValue
  while true:
    digits[count] = int64(ord('0')) + value mod 10
    inc count
    value = value div 10
    if value == 0: break
  result = positionValue
  while count > 0:
    dec count
    buffer[result] = digits[count]
    inc result

proc makeHeader(index: int, block: Block, nonce: int64,
                header: var array[MaxHeader, int64]): int =
  result = appendDecimal(header, 0, int64(index))
  result = appendDecimal(header, result, block.timestampSec)
  header[result] = int64(ord('.')); inc result
  header[result] = int64(ord('0')); inc result
  for i in 0 ..< block.dataLength:
    header[result] = int64(block.data[i])
    inc result
  for i in 0 ..< block.previousHashLength:
    header[result] = int64(block.previousHash[i])
    inc result
  result = appendDecimal(header, result, nonce)

proc toHex(digest: array[32, uint8], output: var array[64, uint8]) =
  const hex = "0123456789abcdef"
  for i in 0 ..< 32:
    output[2 * i] = uint8(ord(hex[int(digest[i] shr 4)]))
    output[2 * i + 1] = uint8(ord(hex[int(digest[i] and 15)]))

proc computeHash(index: int, block: Block, nonce: int64,
                 output: var array[64, uint8]): bool =
  var header: array[MaxHeader, int64]
  var digest: array[32, uint8]
  let length = makeHeader(index, block, nonce, header)
  let hashResult = sha256(cast[ptr UncheckedArray[int64]](addr header[0]), csize_t(length),
                           cast[ptr UncheckedArray[uint8]](addr digest[0]), csize_t(digest.len))
  if hashResult != 32: return false
  toHex(digest, output)
  true

proc hasPrefix(hash: array[64, uint8], difficulty: int64): bool =
  for i in 0 ..< int(difficulty):
    if hash[i] != uint8(ord('0')): return false
  true

proc isValid(blocks: var array[MaxChain, Block], chainLength: int,
             difficulty: int64): bool =
  for i in 1 ..< chainLength:
    if blocks[i].previousHashLength != 64 or
       blocks[i].previousHash != blocks[i - 1].hash or
       not hasPrefix(blocks[i].hash, difficulty):
      return false
    var recomputed: array[64, uint8]
    if not computeHash(i, blocks[i], blocks[i].nonce, recomputed) or
       blocks[i].hash != recomputed:
      return false
  true

proc writeI64(output: var array[MaxOutput, uint8], positionValue: int,
              value: int64): int =
  result = positionValue
  let bits = cast[uint64](value)
  for i in 0 ..< 8:
    output[result] = uint8((bits shr (8 * i)) and 255'u64)
    inc result

proc simple_blockchain*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "simple_blockchain".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxValues): return -1
  let n = int(length)
  let difficulty = input[0]
  let chainLengthValue = input[1]
  if difficulty < 1 or difficulty > 2 or chainLengthValue < 1 or chainLengthValue > int64(MaxChain):
    return -1
  let chainLength = int(chainLengthValue)
  const MaxTimestamp = 2_147_483_647'i64
  if input[2] < 0 or input[2] > MaxTimestamp: return -1

  var blocks: array[MaxChain, Block]
  blocks[0].timestampSec = input[2]
  const genesis = "Genesis Block"
  for i in 0 ..< genesis.len:
    blocks[0].data[i] = uint8(ord(genesis[i]))
  blocks[0].dataLength = genesis.len
  blocks[0].previousHash[0] = uint8(ord('0'))
  blocks[0].previousHashLength = 1

  var cursor = 3
  for i in 1 ..< chainLength:
    if cursor + 2 > n: return -1
    let timestampSec = input[cursor]
    let dataLengthValue = input[cursor + 1]
    cursor += 2
    if timestampSec < 0 or timestampSec > MaxTimestamp or dataLengthValue < 0 or dataLengthValue > int64(MaxData):
      return -1
    let dataLength = int(dataLengthValue)
    if cursor + dataLength > n: return -1
    blocks[i].timestampSec = timestampSec
    blocks[i].dataLength = dataLength
    for j in 0 ..< dataLength:
      let value = input[cursor + j]
      if value < 0 or value > 127: return -1
      blocks[i].data[j] = uint8(value)
    cursor += dataLength
  if cursor != n: return -1

  for i in 0 ..< chainLength:
    if i > 0:
      blocks[i].previousHash = blocks[i - 1].hash
      blocks[i].previousHashLength = 64
    var mined = false
    for nonce in 0 ..< NonceAttempts:
      var candidate: array[64, uint8]
      if not computeHash(i, blocks[i], int64(nonce), candidate): return -1
      if hasPrefix(candidate, difficulty):
        blocks[i].nonce = int64(nonce)
        blocks[i].hash = candidate
        mined = true
        break
    if not mined: return -3

  let valid = if isValid(blocks, chainLength, difficulty): 1'i64 else: 0'i64
  var payload: array[MaxOutput, uint8]
  var written = 0
  written = writeI64(payload, written, 0)
  written = writeI64(payload, written, chainLengthValue)
  for i in 0 ..< chainLength:
    written = writeI64(payload, written, int64(i))
    written = writeI64(payload, written, blocks[i].timestampSec)
    written = writeI64(payload, written, blocks[i].nonce)
    for byte in blocks[i].hash:
      payload[written] = byte
      inc written
  written = writeI64(payload, written, valid)
  if output.isNil or outputCapacity < csize_t(written): return -2
  for i in 0 ..< written:
    output[i] = payload[i]
  int64(written)
