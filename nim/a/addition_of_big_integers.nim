proc addition_of_big_integers*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "addition_of_big_integers".} =
  if input.isNil or length < 4 or length > 68: return -1
  let rawA = input[0]
  let rawB = input[1]
  if rawA < 1 or rawA > 33 or rawB < 1 or rawB > 33: return -1
  let lenA = int(rawA)
  let lenB = int(rawB)
  if int(length) != 2 + lenA + lenB: return -1

  var starts: array[2, int]
  var counts: array[2, int]
  var negatives: array[2, bool]
  starts[0] = 2
  starts[1] = 2 + lenA
  let textLengths = [lenA, lenB]
  for operand in 0 .. 1:
    if textLengths[operand] < 1 or textLengths[operand] > 33: return -1
    negatives[operand] = input[starts[operand]] == 45
    if negatives[operand]: starts[operand] += 1
    counts[operand] = textLengths[operand] - (if negatives[operand]: 1 else: 0)
    if counts[operand] < 1 or counts[operand] > 32: return -1
    for index in 0 ..< counts[operand]:
      let byte = input[starts[operand] + index]
      if byte < 48 or byte > 57: return -1
      if index == 0 and counts[operand] > 1 and byte == 48: return -1
    if negatives[operand] and counts[operand] == 1 and input[starts[operand]] == 48: return -1

  var reversed: array[33, uint8]
  var digits = 0
  var negativeResult = false
  if negatives[0] == negatives[1]:
    negativeResult = negatives[0]
    let width = max(counts[0], counts[1])
    var carry = 0
    for offset in 0 ..< width:
      let da = if offset < counts[0]: int(input[starts[0] + counts[0] - 1 - offset] - 48) else: 0
      let db = if offset < counts[1]: int(input[starts[1] + counts[1] - 1 - offset] - 48) else: 0
      let total = da + db + carry
      reversed[digits] = uint8(total mod 10)
      inc digits
      carry = total div 10
    if carry != 0:
      reversed[digits] = uint8(carry)
      inc digits
  else:
    var order = 0
    if counts[0] > counts[1]: order = 1
    elif counts[0] < counts[1]: order = -1
    else:
      for index in 0 ..< counts[0]:
        if order == 0:
          let da = input[starts[0] + index]
          let db = input[starts[1] + index]
          if da > db: order = 1
          elif da < db: order = -1
    if order == 0:
      reversed[0] = 0
      digits = 1
    else:
      let big = if order > 0: 0 else: 1
      let small = 1 - big
      negativeResult = negatives[big]
      var borrow = 0
      for offset in 0 ..< counts[big]:
        let da = int(input[starts[big] + counts[big] - 1 - offset] - 48)
        let db = if offset < counts[small]: int(input[starts[small] + counts[small] - 1 - offset] - 48) else: 0
        let digit = da - db - borrow
        borrow = if digit < 0: 1 else: 0
        reversed[digits] = uint8(if digit < 0: digit + 10 else: digit)
        inc digits
      while digits > 1 and reversed[digits - 1] == 0: dec digits

  let outputLength = digits + (if negativeResult: 1 else: 0)
  if output.isNil or capacity < csize_t(outputLength): return -2
  var cursor = 0
  if negativeResult:
    output[cursor] = 45
    inc cursor
  for index in 0 ..< digits:
    output[cursor] = uint8(48 + reversed[digits - 1 - index])
    inc cursor
  int64(outputLength)
