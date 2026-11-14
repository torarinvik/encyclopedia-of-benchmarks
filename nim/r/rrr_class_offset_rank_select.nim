proc popcountByte(value: int): int =
  for bit in 0 ..< 8: result += (value shr bit) and 1

proc decode(cls, offset: int): int =
  var remaining = offset
  for candidate in 0 ..< 256:
    if popcountByte(candidate) == cls:
      if remaining == 0: return candidate
      dec remaining
  0

proc rrr_class_offset_rank_select*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "rrr_class_offset_rank_select".} =
  if input == nil or length < 3 or length > 35 or input[0] < 1 or input[0] > 63 or input[1] < 0 or input[2] < 0 or input[2] > 16: return -1
  let n = int(input[0])
  let bits = uint64(input[1])
  let q = int(input[2])
  if bits shr n != 0 or int(length) != 3+2*q: return -1
  for i in 0 ..< q:
    let op = input[3+2*i]
    let index = input[4+2*i]
    if (op != 0 and op != 1) or index < 1 or (op == 0 and index > int64(n)) or (op == 1 and index > 64): return -1
  if output == nil or capacity < csize_t(8*q): return -2
  var classes, offsets: array[8, int]
  var prefix: array[9, int]
  let blocks = (n+7) div 8
  for blockIndex in 0 ..< blocks:
    let byte = int((bits shr (8*blockIndex)) and 255'u64)
    classes[blockIndex] = popcountByte(byte)
    for candidate in 0 ..< byte:
      if popcountByte(candidate) == classes[blockIndex]: inc offsets[blockIndex]
    prefix[blockIndex+1] = prefix[blockIndex]+classes[blockIndex]
  for i in 0 ..< q:
    let op = input[3+2*i]
    let index = int(input[4+2*i])
    var answer = -1
    if op == 0:
      let blockIndex = (index-1) div 8
      let byte = decode(classes[blockIndex], offsets[blockIndex])
      answer = prefix[blockIndex]
      for bit in 0 ..< index-8*blockIndex: answer += (byte shr bit) and 1
    else:
      var blockIndex = 0
      while blockIndex < blocks and prefix[blockIndex+1] < index: inc blockIndex
      if blockIndex < blocks:
        var remaining = index-prefix[blockIndex]
        let byte = decode(classes[blockIndex], offsets[blockIndex])
        for bit in 0 ..< min(8, n-8*blockIndex):
          if ((byte shr bit) and 1) != 0:
            dec remaining
            if remaining == 0:
              answer = 8*blockIndex+bit+1
              break
    var encoded = cast[uint64](int64(answer))
    for byte in 0 ..< 8:
      output[8*i+byte] = uint8(encoded and 255'u64)
      encoded = encoded shr 8
  int64(8*q)
