import std/math

const MaxTerm = 128
const MaxText = 4096
const MaxPacked = 4227
const MaxCount = 1_000_000'i64
proc punct(c: uint8): bool = (c >= 33 and c <= 47) or (c >= 58 and c <= 64) or (c >= 91 and c <= 96) or (c >= 123 and c <= 126)
proc lowerAscii(c: uint8): uint8 = if c >= 65 and c <= 90: c + 32 else: c
proc put32(outp: ptr UncheckedArray[uint8], pos: var int, value: uint32) =
  var bits = value
  for _ in 0 ..< 4: outp[pos] = uint8(bits and 255); inc pos; bits = bits shr 8
proc put64(outp: ptr UncheckedArray[uint8], pos: var int, value: int64) =
  var bits = cast[uint64](value)
  for _ in 0 ..< 8: outp[pos] = uint8(bits and 255); inc pos; bits = bits shr 8
proc milli(x: float64): int64 =
  let y = x * 1000.0
  let lo = floor(y)
  let frac = y - lo
  if frac < 0.5: return int64(lo)
  if frac > 0.5: return int64(lo + 1.0)
  let k = int64(lo)
  if k mod 2 == 0: k else: k + 1

proc word_frequency_functions*(input: ptr UncheckedArray[int64], length: csize_t,
                               output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "word_frequency_functions".} =
  if input == nil or length < 1 or length > MaxPacked: return -1
  let op = input[0]
  var kind = 0'i64
  var a = 0'i64
  var b = 0'i64
  var outLen = 12
  if op == 0 or op == 1:
    if length < 3 or input[1] < 0 or input[1] > MaxTerm: return -1
    let termLen = int(input[1])
    let textLenIndex = 2 + termLen
    if int(length) < textLenIndex + 1 or input[textLenIndex] < 0 or input[textLenIndex] > MaxText: return -1
    let textLen = int(input[textLenIndex])
    let textIndex = textLenIndex + 1
    if int(length) != textIndex + textLen: return -1
    var term: array[MaxTerm, uint8]
    var text: array[MaxText, uint8]
    var clean: array[MaxText, uint8]
    for i in 0 ..< termLen:
      let value = input[2 + i]
      if value < 0 or value > 127: return -1
      term[i] = lowerAscii(uint8(value))
    for i in 0 ..< textLen:
      let value = input[textIndex + i]
      if value < 0 or value > 127: return -1
      text[i] = uint8(value)
    var cleanLen = 0
    for i in 0 ..< textLen:
      if not punct(text[i]) and (op != 0 or text[i] != 10):
        clean[cleanLen] = if op == 1: lowerAscii(text[i]) else: text[i]
        inc cleanLen
    if op == 0:
      var start = 0
      for i in 0 .. cleanLen:
        if i == cleanLen or clean[i] == 32:
          let n = i - start
          var same = n == termLen
          var j = 0
          while same and j < n:
            if lowerAscii(clean[start + j]) != term[j]: same = false
            inc j
          if same: inc a
          start = i + 1
    else:
      kind = 1
      outLen = 20
      var start = 0
      for i in 0 .. cleanLen:
        if i == cleanLen or clean[i] == 10:
          let n = i - start
          var found = termLen == 0
          var j = 0
          while not found and j + termLen <= n:
            var k = 0
            while k < termLen and clean[start + j + k] == term[k]: inc k
            if k == termLen: found = true
            inc j
          if found: inc a
          inc b
          start = i + 1
  elif op == 2:
    if length != 4: return -1
    let df = input[1]; let n = input[2]; let smoothing = input[3]
    if df < 0 or df > MaxCount or n < 0 or n > MaxCount or (smoothing != 0 and smoothing != 1): return -1
    if smoothing == 1 and n == 0: kind = 4; outLen = 4
    elif smoothing == 0 and df == 0: kind = 3; outLen = 4
    elif smoothing == 0 and n == 0: kind = 4; outLen = 4
    else:
      let value = if smoothing == 1: 1.0 + log10(float64(n) / float64(1 + df)) else: log10(float64(n) / float64(df))
      kind = 2
      a = milli(value)
  elif op == 3:
    if length != 3 or input[1] < 0 or input[1] > MaxCount or input[2] < -MaxCount or input[2] > MaxCount: return -1
    kind = 2
    a = input[1] * input[2]
  else: return -1
  if output == nil or capacity < csize_t(outLen): return -2
  var pos = 0
  put32(output, pos, uint32(kind))
  if kind == 0 or kind == 2: put64(output, pos, a)
  elif kind == 1: put64(output, pos, a); put64(output, pos, b)
  int64(pos)
