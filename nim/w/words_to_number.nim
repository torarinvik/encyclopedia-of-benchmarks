const maxInput = 128
const maxTokens = 128
const maxFractionWords = 3
const words = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
  "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen",
  "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety", "hundred", "thousand",
  "million", "billion", "trillion", "and", "point", "negative"]

proc wordId(input: ptr UncheckedArray[int64], start, finish: int): int =
  for index, word in words:
    if word.len != finish - start: continue
    var matched = true
    for offset in 0 ..< word.len:
      var ch = int(input[1 + start + offset])
      if ch >= 65 and ch <= 90: ch += 32
      if ch != ord(word[offset]): matched = false
    if matched: return index + 1
  0
proc numberValue(id: int): int64 =
  if id >= 1 and id <= 20: return int64(id - 1)
  if id >= 21 and id <= 28: return int64((id - 19) * 10)
  -1
proc digits10(value: int64): int =
  var x = value
  result = 1
  while x >= 10: x = x div 10; inc result
proc appendUint(out: var array[64, uint8], at: var int, value: int64) =
  var reversed: array[24, uint8]
  var x = value
  var used = 0
  while true:
    reversed[used] = uint8(ord('0') + int(x mod 10)); inc used; x = x div 10
    if x == 0: break
  while used > 0: dec used; out[at] = reversed[used]; inc at
proc isSeparator(value: int64): bool = value == 32 or value == 44 or value == 45
proc parseNumber(input: ptr UncheckedArray[int64], byteCount: int, text: var array[64, uint8], textLen: var int): int64 =
  var tokens: array[maxTokens, int]
  var count = 0
  var start = maxInput + 1
  for i in 0 ..< byteCount:
    let ch = input[i + 1]
    if ch < 32 or ch > 126: return -1
    if isSeparator(ch):
      if start != maxInput + 1:
        if count >= maxTokens: return -1
        tokens[count] = wordId(input, start, i); inc count; start = maxInput + 1
    elif start == maxInput + 1: start = i
  if start != maxInput + 1:
    if count >= maxTokens: return -1
    tokens[count] = wordId(input, start, byteCount); inc count
  if count == 0: return -3
  let negative = tokens[0] == 36
  let pos = if negative: 1 else: 0
  var chunks: array[maxTokens, int64]
  var chunkCount = 0
  var current: int64 = 0
  var prevHundred = false
  var prevScale = false
  var fraction: array[16, uint8]
  var fractionLen = 0
  var hasPoint = false
  for i in pos ..< count:
    let id = tokens[i]
    if id == 34:
      if i + 1 >= count: return -10
      let value = numberValue(tokens[i + 1])
      let after = if i + 2 < count: tokens[i + 2] else: -1
      if (not prevHundred and not prevScale) or value < 0 or not (value >= 10 or after == -1 or after == 35): return -10
      continue
    if id == 29:
      if current >= 10 or prevScale: return -5
      if current == 0: current = 1
      current *= 100; prevHundred = true
      continue
    prevHundred = false
    if id >= 30 and id <= 33:
      if current == 0 or prevScale: return -5
      let scale = if id == 30: 1000'i64 elif id == 31: 1000000'i64 elif id == 32: 1000000000'i64 else: 1000000000000'i64
      let next = current * scale
      if chunkCount > 0 and digits10(chunks[chunkCount - 1]) <= digits10(next): return -5
      chunks[chunkCount] = next; inc chunkCount; current = 0; prevScale = true
      continue
    prevScale = false
    let value = numberValue(id)
    if value >= 0:
      if value == 0 and not (current == 0 and chunkCount == 0): return -5
      if current != 0 and digits10(current) <= digits10(value): return -5
      current += value
      continue
    if id == 35:
      if current != 0: chunks[chunkCount] = current; inc chunkCount
      current = 0; hasPoint = true
      var wordCount = 0
      for j in i + 1 ..< count:
        let digit = numberValue(tokens[j])
        if digit < 0: return -6
        inc wordCount
        if wordCount > maxFractionWords: return -1
        var at = fractionLen; appendUint(text, at, digit)
        for k in fractionLen ..< at: fraction[k] = text[k]
        fractionLen = at
      if wordCount == 0: return -7
      break
    if id == 36: return (if negative: -8'i64 else: -9'i64)
    return -4
  if current != 0: chunks[chunkCount] = current; inc chunkCount
  var total: int64 = 0
  for i in 0 ..< chunkCount: total += chunks[i]
  var fractionNonzero = false
  for i in 0 ..< fractionLen:
    if fraction[i] != uint8(ord('0')): fractionNonzero = true
  textLen = 0
  if negative and (total != 0 or fractionNonzero): text[textLen] = uint8(ord('-')); inc textLen
  appendUint(text, textLen, total)
  if hasPoint:
    text[textLen] = uint8(ord('.')); inc textLen
    for i in 0 ..< fractionLen: text[textLen] = fraction[i]; inc textLen
  0

proc words_to_number*(input: ptr UncheckedArray[int64], length: csize_t,
                      output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "words_to_number".} =
  if input == nil or length < 1 or length > maxInput + 1: return -1
  let n = input[0]
  if n < 0 or n > maxInput or length != csize_t(n + 1): return -1
  var text: array[64, uint8]
  var textLen = 0
  let status = parseNumber(input, int(n), text, textLen)
  if status != 0: return status
  if output == nil or capacity < csize_t(textLen): return -2
  for i in 0 ..< textLen: output[i] = text[i]
  int64(textLen)
