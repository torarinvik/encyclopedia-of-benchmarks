const MaxText = 64
const Scratch = 128
const CodeBytes = 10

proc replaceAll(text: var array[Scratch, char], length: var int,
                old, replacement: openArray[char]) =
  var next: array[Scratch, char]
  var out = 0
  var at = 0
  while at < length:
    var matched = old.len > 0 and at + old.len <= length
    if matched:
      for j in 0 ..< old.len:
        if text[at + j] != old[j]: matched = false
    if matched:
      for ch in replacement:
        next[out] = ch
        inc out
      at += old.len
    else:
      next[out] = text[at]
      inc out
      inc at
  for i in 0 ..< out: text[i] = next[i]
  length = out

proc replacePrefix(text: var array[Scratch, char], length: var int,
                   old, replacement: openArray[char]) =
  if length < old.len: return
  for i in 0 ..< old.len:
    if text[i] != old[i]: return
  let tail = length - old.len
  for i in countdown(tail - 1, 0):
    text[replacement.len + i] = text[old.len + i]
  for i in 0 ..< replacement.len: text[i] = replacement[i]
  length = replacement.len + tail

proc replaceSuffix(text: var array[Scratch, char], length: var int,
                   old, replacement: openArray[char]) =
  if length < old.len: return
  let start = length - old.len
  for i in 0 ..< old.len:
    if text[start + i] != old[i]: return
  for i in 0 ..< replacement.len: text[start + i] = replacement[i]
  length = start + replacement.len

proc replaceChar(text: var array[Scratch, char], length: int, old, replacement: char) =
  for i in 0 ..< length:
    if text[i] == old: text[i] = replacement

proc squeeze(text: var array[Scratch, char], length: var int, letter, marker: char) =
  var out = 0
  for i in 0 ..< length:
    if text[i] == letter and out > 0 and text[out - 1] == marker: continue
    text[out] = if text[i] == letter: marker else: text[i]
    inc out
  length = out

proc encode(values: ptr UncheckedArray[int64], result: var array[CodeBytes, char]) =
  var text: array[Scratch, char]
  var n = int(values[0])
  for i in 0 ..< n:
    let code = values[i + 1]
    text[i] = char(if code >= 65 and code <= 90: code + 32 else: code)
  if n == 0:
    for i in 0 ..< CodeBytes: result[i] = '1'
    return
  if text[n - 1] == 'e': dec n
  replacePrefix(text, n, "cough", "cou2f")
  replacePrefix(text, n, "rough", "rou2f")
  replacePrefix(text, n, "tough", "tou2f")
  replacePrefix(text, n, "enough", "enou2f")
  replacePrefix(text, n, "trough", "trou2f")
  replacePrefix(text, n, "gn", "2n")
  replaceSuffix(text, n, "mb", "m2")
  replaceAll(text, n, "cq", "2q"); replaceAll(text, n, "ci", "si")
  replaceAll(text, n, "ce", "se"); replaceAll(text, n, "cy", "sy")
  replaceAll(text, n, "tch", "2ch")
  replaceChar(text, n, 'c', 'k'); replaceChar(text, n, 'q', 'k')
  replaceChar(text, n, 'x', 'k'); replaceChar(text, n, 'v', 'f')
  replaceAll(text, n, "dg", "2g"); replaceAll(text, n, "tio", "sio")
  replaceAll(text, n, "tia", "sia"); replaceChar(text, n, 'd', 't')
  replaceAll(text, n, "ph", "fh"); replaceChar(text, n, 'b', 'p')
  replaceAll(text, n, "sh", "s2"); replaceChar(text, n, 'z', 's')
  if n > 0 and text[0] in {'a', 'e', 'i', 'o', 'u'}: text[0] = 'A'
  for i in 0 ..< n:
    if text[i] in {'a', 'e', 'i', 'o', 'u'}: text[i] = '3'
  replaceChar(text, n, 'j', 'y')
  replacePrefix(text, n, "y3", "Y3")
  replacePrefix(text, n, "y", "A")
  replaceChar(text, n, 'y', '3')
  replaceAll(text, n, "3gh3", "3kh3"); replaceAll(text, n, "gh", "22")
  replaceChar(text, n, 'g', 'k')
  squeeze(text, n, 's', 'S'); squeeze(text, n, 't', 'T'); squeeze(text, n, 'p', 'P')
  squeeze(text, n, 'k', 'K'); squeeze(text, n, 'f', 'F'); squeeze(text, n, 'm', 'M'); squeeze(text, n, 'n', 'N')
  replaceAll(text, n, "w3", "W3"); replaceAll(text, n, "wh3", "Wh3")
  replaceSuffix(text, n, "w", "3"); replaceChar(text, n, 'w', '2')
  replacePrefix(text, n, "h", "A"); replaceChar(text, n, 'h', '2')
  replaceAll(text, n, "r3", "R3"); replaceSuffix(text, n, "r", "3"); replaceChar(text, n, 'r', '2')
  replaceAll(text, n, "l3", "L3"); replaceSuffix(text, n, "l", "3"); replaceChar(text, n, 'l', '2')
  var out = 0
  for i in 0 ..< n:
    if text[i] != '2': text[out] = text[i]; inc out
  n = out
  replaceSuffix(text, n, "3", "A")
  out = 0
  for i in 0 ..< n:
    if text[i] != '3': text[out] = text[i]; inc out
  n = out
  for i in 0 ..< CodeBytes: result[i] = if i < n: text[i] else: '1'

proc caverphone_2_encoder*(values: ptr UncheckedArray[int64], length: csize_t,
                           output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
                           {.cdecl, exportc: "caverphone_2_encoder".} =
  if values.isNil or length < 1 or length > MaxText + 1: return -1
  let count = values[0]
  if count < 0 or count > MaxText or length != csize_t(count + 1): return -1
  for i in 0 ..< int(count):
    let code = values[i + 1]
    if not ((code >= 65 and code <= 90) or (code >= 97 and code <= 122)): return -1
  if output.isNil or outputCapacity < CodeBytes: return -2
  var result: array[CodeBytes, char]
  encode(values, result)
  for i in 0 ..< CodeBytes: output[i] = uint8(ord(result[i]))
  int64(CodeBytes)
