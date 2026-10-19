# Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC).
# Apache-2.0 licensed upstream kernel, bounded variant; modifications made.
const MaxText = 96

proc scanText(text: var array[MaxText, uint8], n: int,
    finals: var array[8, uint32], transitions: var array[8, uint32]) =
  var pos = 0
  while pos < n:
    var state = 0
    while pos < n and state != 1:
      let ch = text[pos]
      if ch == uint8(ord(',')):
        inc pos
        break
      let digit = ch >= uint8(ord('0')) and ch <= uint8(ord('9'))
      case state
      of 0:
        if digit: state = 4
        elif ch == uint8(ord('+')) or ch == uint8(ord('-')): state = 2
        elif ch == uint8(ord('.')): state = 5
        else: state = 1; inc transitions[1]
        inc transitions[0]
      of 2:
        if digit: state = 4
        elif ch == uint8(ord('.')): state = 5
        else: state = 1
        inc transitions[2]
      of 4:
        if ch == uint8(ord('.')): state = 5; inc transitions[4]
        elif not digit: state = 1; inc transitions[4]
      of 5:
        if ch == uint8(ord('e')) or ch == uint8(ord('E')): state = 3; inc transitions[5]
        elif not digit: state = 1; inc transitions[5]
      of 3:
        if ch == uint8(ord('+')) or ch == uint8(ord('-')): state = 6
        else: state = 1
        inc transitions[3]
      of 6:
        if digit: state = 7
        else: state = 1
        inc transitions[6]
      of 7:
        if not digit: state = 1; inc transitions[1]
      else: discard
      inc pos
    inc finals[state]

proc numeric_token_state_machine*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "numeric_token_state_machine".} =
  if input == nil or length < 4 or length > csize_t(MaxText + 3): return -1
  let rawN = input[0]; let step = input[1]; let seed = input[2]
  if rawN < 1 or rawN > int64(MaxText) or length != csize_t(rawN + 3) or step < 1 or step > 16 or seed < 1 or seed > 255: return -1
  let n = int(rawN)
  var text: array[MaxText, uint8]
  for i in 0 ..< n:
    if input[3+i] < 32 or input[3+i] > 126: return -1
    text[i] = uint8(input[3+i])
  if text[0] == uint8(ord(',')) or text[n-1] == uint8(ord(',')): return -1
  for i in 1 ..< n: if text[i] == uint8(ord(',')) and text[i-1] == uint8(ord(',')): return -1
  for i in countup(0, n-1, int(step)):
    if text[i] != uint8(ord(',')) and ((text[i] xor uint8(seed)) == uint8(ord(',')) or (text[i] xor uint8(seed)) == 0): return -1
  var finals: array[8, uint32]
  var transitions: array[8, uint32]
  scanText(text,n,finals,transitions)
  for i in countup(0,n-1,int(step)): if text[i] != uint8(ord(',')): text[i] = text[i] xor uint8(seed)
  scanText(text,n,finals,transitions)
  for i in countup(0,n-1,int(step)): if text[i] != uint8(ord(',')): text[i] = text[i] xor uint8(seed)
  if output == nil or outputCapacity < 64: return -2
  for i in 0 ..< 8:
    for b in 0 ..< 4:
      output[i*8+b] = uint8((finals[i] shr (8*b)) and 255)
      output[i*8+4+b] = uint8((transitions[i] shr (8*b)) and 255)
  64
