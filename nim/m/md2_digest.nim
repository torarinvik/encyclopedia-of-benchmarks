import std/math

const Md2S: array[256, uint8] = [
  41'u8,46,67,201,162,216,124,1,61,54,84,161,236,240,6,19,98,167,5,243,192,199,115,140,152,147,43,217,188,76,130,202,
  30,155,87,60,253,212,224,22,103,66,111,24,138,23,229,18,190,78,196,214,218,158,222,73,160,251,245,142,187,47,238,122,
  169,104,121,145,21,178,7,63,148,194,16,137,11,34,95,33,128,127,93,154,90,144,50,39,53,62,204,231,191,247,151,3,
  255,25,48,179,72,165,181,209,215,94,146,42,172,86,170,198,79,184,56,210,150,164,125,182,118,252,107,226,156,116,4,241,
  69,157,112,89,100,113,135,32,134,91,207,101,230,45,168,2,27,96,37,173,174,176,185,246,28,70,97,105,52,64,126,15,
  85,71,163,35,221,81,175,58,195,92,249,206,186,197,234,38,44,83,13,110,133,40,132,9,211,223,205,244,65,129,77,82,
  106,220,55,200,108,193,171,250,36,225,123,8,12,189,177,74,120,136,149,139,227,99,232,109,233,203,213,254,59,0,29,57,
  242,239,183,14,102,88,208,228,166,119,114,248,235,117,75,10,49,68,80,180,143,237,31,26,219,153,141,51,159,17,131,20]

proc md2Digest*(input: ptr UncheckedArray[float64], length: csize_t,
                output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
                {.cdecl, exportc: "md2_digest".} =
  if length > 63 or (length > 0 and input == nil): return -1
  let count = int(length)
  var bytes: array[64, uint8]
  for index in 0 ..< count:
    let value = input[index]
    if classify(value) in {fcNan, fcInf, fcNegInf} or value < 0.0 or value > 255.0 or value != floor(value): return -1
    bytes[index] = uint8(value)
  if output == nil or outputCapacity < 16: return -2

  let paddingLength = 16 - count mod 16
  let paddedLength = count + paddingLength
  for index in count ..< paddedLength: bytes[index] = uint8(paddingLength)
  var checksum: array[16, uint8]
  var last = 0'u8
  for offset in countup(0, paddedLength - 16, 16):
    for index in 0 ..< 16:
      checksum[index] = checksum[index] xor Md2S[int(bytes[offset + index] xor last)]
      last = checksum[index]

  var state: array[48, uint8]
  for offset in countup(0, paddedLength, 16):
    for index in 0 ..< 16:
      let value = if offset < paddedLength: bytes[offset + index] else: checksum[index]
      state[index + 16] = value
      state[index + 32] = state[index] xor value
    var temporary = 0'u8
    for round in 0 ..< 18:
      for index in 0 ..< 48:
        state[index] = state[index] xor Md2S[int(temporary)]
        temporary = state[index]
      temporary = uint8((int(temporary) + round) mod 256)
  for index in 0 ..< 16: output[index] = float64(state[index])
  16
