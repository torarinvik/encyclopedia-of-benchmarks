## Baconian cipher with explicit Java, Python, and Rust source dialects.
const MaxPayload = 1024

proc pythonCodeForLetter(upper: int): int =
  if upper >= ord('A') and upper <= ord('I'): return upper - ord('A')
  if upper == ord('J'): return 28
  if upper >= ord('K') and upper <= ord('U'): return upper - ord('A') - 1
  if upper == ord('V'): return 29
  if upper >= ord('W') and upper <= ord('Z'): return upper - ord('A') - 2
  -1

proc pythonLetterForCode(code: int): int =
  if code >= 0 and code <= 8: return ord('a') + code
  if code == 28: return ord('j')
  if code == 29: return ord('v')
  if code >= 9 and code <= 19: return ord('a') + code + 1
  if code >= 20 and code <= 23: return ord('a') + code + 2
  -1

proc decodeCode(values: ptr UncheckedArray[int64], start: int): int =
  var code = 0
  for bit in 0 ..< 5: code = (code shl 1) or (if values[start + bit] == ord('B'): 1 else: 0)
  code

proc writeCode(output: ptr UncheckedArray[uint8], position: var int, code: int) =
  for bit in countdown(4, 0):
    output[position] = uint8(if ((code shr bit) and 1) != 0: ord('B') else: ord('A'))
    inc position

proc pythonDecodeLength(values: ptr UncheckedArray[int64], n: int): int =
  var words = 0
  var letters = 0
  var used = 0
  var code = 0
  var inWord = false
  for i in 0 ..< n:
    let value = values[i + 2]
    if value == ord(' '):
      if used != 0: return -1
      if inWord:
        inc words
        inWord = false
    else:
      if value != ord('A') and value != ord('B'): return -1
      inWord = true
      code = (code shl 1) or (if value == ord('B'): 1 else: 0)
      inc used
      if used == 5:
        if pythonLetterForCode(code) < 0: return -1
        inc letters
        used = 0
        code = 0
  if used != 0: return -1
  if inWord: inc words
  letters + max(0, words - 1)

proc baconian_cipher*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "baconian_cipher".} =
  if values == nil or length < 2 or length > csize_t(MaxPayload + 2): return -1
  let mode = values[0]
  let dialect = values[1]
  if (mode != 0 and mode != 1) or dialect < 0 or dialect > 2: return -1
  let n = int(length) - 2
  for i in 0 ..< n:
    if values[i + 2] < 0 or values[i + 2] > 127: return -1

  var outputLength = 0
  if mode == 0:
    for i in 0 ..< n:
      let value = int(values[i + 2])
      let upper = if value >= ord('a') and value <= ord('z'): value - 32 else: value
      let isLetter = upper >= ord('A') and upper <= ord('Z')
      if dialect == 0:
        if isLetter: outputLength += 5
      elif dialect == 1:
        if value == ord(' '): inc outputLength
        elif isLetter: outputLength += 5
        else: return -1
      else:
        if isLetter:
          if upper > ord('X'): return -1
          outputLength += 5
        else: inc outputLength
  elif dialect == 0:
    if n mod 5 != 0: return -1
    for i in 0 ..< n:
      if values[i + 2] != ord('A') and values[i + 2] != ord('B'): return -1
    for group in 0 ..< (n div 5):
      if decodeCode(values, 2 + group * 5) > 25: return -1
    outputLength = n div 5
  elif dialect == 1:
    outputLength = pythonDecodeLength(values, n)
    if outputLength < 0: return -1
  else:
    outputLength = (n + 4) div 5
  if outputCapacity < csize_t(outputLength) or (outputLength > 0 and output == nil): return -2

  var write = 0
  if mode == 0:
    for i in 0 ..< n:
      let value = int(values[i + 2])
      let upper = if value >= ord('a') and value <= ord('z'): value - 32 else: value
      if dialect == 0:
        if upper >= ord('A') and upper <= ord('Z'): writeCode(output, write, if upper == ord('I'): 9 else: upper - ord('A'))
      elif dialect == 1:
        if value == ord(' '):
          output[write] = uint8(ord(' '))
          inc write
        else: writeCode(output, write, pythonCodeForLetter(upper))
      else:
        if upper >= ord('A') and upper <= ord('Z'): writeCode(output, write, upper - ord('A'))
        else:
          output[write] = uint8(value)
          inc write
  elif dialect == 0:
    for group in 0 ..< (n div 5):
      let code = decodeCode(values, 2 + group * 5)
      output[write] = uint8(if code == 8 or code == 9: ord('I') else: ord('A') + code)
      inc write
  elif dialect == 1:
    var i = 0
    var firstWord = true
    while i < n:
      while i < n and values[i + 2] == ord(' '): inc i
      if i == n: break
      if not firstWord:
        output[write] = uint8(ord(' '))
        inc write
      firstWord = false
      while i < n and values[i + 2] != ord(' '):
        output[write] = uint8(pythonLetterForCode(decodeCode(values, i + 2)))
        inc write
        i += 5
  else:
    var i = 0
    while i < n:
      if n - i < 5:
        output[write] = uint8(ord(' '))
        inc write
        break
      var code = 0
      var valid = true
      for bit in 0 ..< 5:
        let value = values[i + 2 + bit]
        if value != ord('A') and value != ord('B'): valid = false
        code = (code shl 1) or (if value == ord('B'): 1 else: 0)
      output[write] = uint8(if valid and code < 24: ord('A') + code else: ord(' '))
      inc write
      i += 5
  int64(outputLength)
