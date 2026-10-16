const MaxText = 256
proc trifid_cipher*(input: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], output_capacity: csize_t): int64 {.cdecl, exportc: "trifid_cipher".} =
  if input.isNil or length < 31: return -1
  let mode = input[0]
  let periodValue = input[1]
  let nValue = input[2]
  if (mode != 0 and mode != 1) or periodValue < 1 or periodValue > 256 or nValue < 0 or nValue > MaxText or input[3] != 27 or length != csize_t(31 + nValue): return -1
  let period = int(periodValue)
  var alphabet: array[27, int]
  var text: array[MaxText, int]
  var transformed: array[MaxText, int]
  var alen = 0
  var tlen = 0
  for i in 0 ..< 27:
    let value = input[4 + int(nValue) + i]
    if value < 0 or value > 127: return -1
    var c = int(value)
    if c >= 97 and c <= 122: c -= 32
    if c == 32: continue
    for j in 0 ..< alen:
      if alphabet[j] == c: return -1
    alphabet[alen] = c
    alen += 1
  if alen != 27: return -1
  for i in 0 ..< int(nValue):
    let value = input[4 + i]
    if value < 0 or value > 127: return -1
    var c = int(value)
    if c >= 97 and c <= 122: c -= 32
    if c == 32: continue
    var found = false
    for j in 0 ..< 27:
      if alphabet[j] == c: found = true
    if not found: return -1
    text[tlen] = c
    tlen += 1
  var start = 0
  while start < tlen:
    let k = min(period, tlen - start)
    var digits: array[768, int]
    if mode == 0:
      var m = 0
      for axis in 0 ..< 3:
        for i in 0 ..< k:
          var index = 0
          while alphabet[index] != text[start + i]: index += 1
          digits[m] = (index div (if axis == 0: 9 elif axis == 1: 3 else: 1)) mod 3 + 49
          m += 1
      for i in countup(0, m - 1, 3):
        let index = (digits[i] - 49) * 9 + (digits[i + 1] - 49) * 3 + digits[i + 2] - 49
        transformed[start + i div 3] = alphabet[index]
    else:
      for i in 0 ..< k:
        var index = 0
        while alphabet[index] != text[start + i]: index += 1
        digits[3 * i] = (index div 9) mod 3 + 49
        digits[3 * i + 1] = (index div 3) mod 3 + 49
        digits[3 * i + 2] = index mod 3 + 49
      for i in 0 ..< k:
        let index = (digits[i] - 49) * 9 + (digits[k + i] - 49) * 3 + digits[2 * k + i] - 49
        transformed[start + i] = alphabet[index]
    start += k
  if output_capacity < csize_t(tlen): return -2
  if tlen > 0 and output.isNil: return -1
  for i in 0 ..< tlen: output[i] = uint8(transformed[i])
  int64(tlen)
