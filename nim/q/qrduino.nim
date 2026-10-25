## Clean-room bounded QR encoder; package README documents source provenance.
## SPDX-License-Identifier: GPL-3.0-or-later
const
  QrSide = 25
  QrCells = 625
  DataWords = 34
  EccWords = 10
  MaxMessage = 21
  PrefixBytes = 22

proc gfMultiply(leftInput, rightInput: uint8): uint8 =
  var left = uint16(leftInput)
  var right = rightInput
  var product: uint16 = 0
  while right != 0:
    if (right and 1) != 0: product = product xor left
    right = right shr 1
    left = left shl 1
    if (left and 0x100) != 0: left = left xor 0x11D
  uint8(product)

proc putBits(target: var array[DataWords, uint8], position: var int,
             value: uint32, width: int) =
  for bit in countdown(width - 1, 0):
    if ((value shr bit) and 1) != 0:
      target[position div 8] = target[position div 8] or uint8(0x80 shr (position mod 8))
    inc position

proc mark(frame: var array[QrCells, uint8], reserved: var array[QrCells, uint8],
          x, y: int, dark: bool) =
  if x < 0 or x >= QrSide or y < 0 or y >= QrSide: return
  let index = y * QrSide + x
  reserved[index] = 1
  if dark: frame[index] = 1

proc finder(frame: var array[QrCells, uint8], reserved: var array[QrCells, uint8],
            left, top: int) =
  mark(frame, reserved, left + 3, top + 3, true)
  for j in 0 ..< 6:
    mark(frame, reserved, left + j, top, true)
    mark(frame, reserved, left, top + j + 1, true)
    mark(frame, reserved, left + 6, top + j, true)
    mark(frame, reserved, left + j + 1, top + 6, true)
  for j in 1 ..< 5:
    mark(frame, reserved, left + j, top + 1, false)
    mark(frame, reserved, left + 1, top + j + 1, false)
    mark(frame, reserved, left + 5, top + j, false)
    mark(frame, reserved, left + j + 1, top + 5, false)
  for j in 2 ..< 4:
    mark(frame, reserved, left + j, top + 2, true)
    mark(frame, reserved, left + 2, top + j + 1, true)
    mark(frame, reserved, left + 4, top + j, true)
    mark(frame, reserved, left + j + 1, top + 4, true)

proc alignment(frame: var array[QrCells, uint8], reserved: var array[QrCells, uint8],
               cx, cy: int) =
  mark(frame, reserved, cx, cy, true)
  for j in -2 ..< 2:
    mark(frame, reserved, cx + j, cy - 2, true)
    mark(frame, reserved, cx - 2, cy + j + 1, true)
    mark(frame, reserved, cx + 2, cy + j, true)
    mark(frame, reserved, cx + j + 1, cy + 2, true)
  for j in 0 ..< 2:
    mark(frame, reserved, cx - 1, cy + j, false)
    mark(frame, reserved, cx + 1, cy - j, false)
    mark(frame, reserved, cx - j, cy - 1, false)
    mark(frame, reserved, cx + j, cy + 1, false)

proc baseFrame(frame: var array[QrCells, uint8], reserved: var array[QrCells, uint8]) =
  finder(frame, reserved, 0, 0)
  finder(frame, reserved, QrSide - 7, 0)
  finder(frame, reserved, 0, QrSide - 7)
  alignment(frame, reserved, 18, 18)
  mark(frame, reserved, 8, QrSide - 8, true)
  for x in 0 ..< 9: mark(frame, reserved, x, 8, false)
  for x in 0 ..< 8:
    mark(frame, reserved, x + QrSide - 8, 8, false)
    mark(frame, reserved, 8, x, false)
  for y in 0 ..< 7: mark(frame, reserved, 8, y + QrSide - 7, false)
  for p in 0 ..< QrSide - 14:
    let dark = (p and 1) == 0
    mark(frame, reserved, 8 + p, 6, dark)
    mark(frame, reserved, 6, 8 + p, dark)
  for y in 0 ..< QrSide:
    for x in 0 .. y:
      let index = y * QrSide + x
      if frame[index] != 0: reserved[index] = 1

proc makeCodewords(message: array[MaxMessage, uint8], messageLength: int,
                   words: var array[DataWords + EccWords, uint8]) =
  var data: array[DataWords, uint8]
  var position = 0
  putBits(data, position, 4, 4)
  putBits(data, position, uint32(messageLength), 8)
  for i in 0 ..< messageLength: putBits(data, position, uint32(message[i]), 8)
  let remaining = DataWords * 8 - position
  putBits(data, position, 0, min(remaining, 4))
  while (position and 7) != 0: putBits(data, position, 0, 1)
  var pad: uint32 = 0xEC
  while position < DataWords * 8:
    putBits(data, position, pad, 8)
    pad = if pad == 0xEC: 0x11 else: 0xEC

  var generator: array[EccWords + 1, uint8]
  generator[0] = 1
  var degree = 0
  var root: uint8 = 1
  for _ in 0 ..< EccWords:
    generator[degree + 1] = 1
    for j in countdown(degree, 1):
      let prior = generator[j - 1]
      let current = generator[j]
      generator[j] = if current != 0: prior xor gfMultiply(current, root) else: prior
    generator[0] = gfMultiply(generator[0], root)
    inc degree
    root = gfMultiply(root, 2)
  var ecc: array[EccWords, uint8]
  for i in 0 ..< DataWords:
    let factor = data[i] xor ecc[0]
    for j in 0 ..< EccWords - 1:
      ecc[j] = ecc[j + 1] xor gfMultiply(factor, generator[j + 1])
    ecc[EccWords - 1] = gfMultiply(factor, generator[0])
  for i in 0 ..< DataWords: words[i] = data[i]
  for i in 0 ..< EccWords: words[DataWords + i] = ecc[i]

proc placeData(frame: var array[QrCells, uint8], reserved: array[QrCells, uint8],
               words: array[DataWords + EccWords, uint8]) =
  var x = QrSide - 1
  var y = QrSide - 1
  var movingUp = true
  var movingLeft = true
  for word in words:
    var current = word
    for _ in 0 ..< 8:
      if (current and 0x80) != 0: frame[y * QrSide + x] = 1
      current = current shl 1
      while true:
        if movingLeft: dec x
        else:
          inc x
          if movingUp:
            if y != 0: dec y
            else:
              x -= 2
              movingUp = false
              if x == 6:
                dec x
                y = 9
          elif y != QrSide - 1: inc y
          else:
            x -= 2
            movingUp = true
            if x == 6:
              dec x
              y -= 8
        movingLeft = not movingLeft
        if reserved[y * QrSide + x] == 0: break

proc maskedBy(mask, x, y: int): bool =
  let product = x * y
  case mask
  of 0: (x + y) mod 2 == 0
  of 1: y mod 2 == 0
  of 2: x mod 3 == 0
  of 3: (x + y) mod 3 == 0
  of 4: (y div 2 + x div 3) mod 2 == 0
  of 5: product mod 2 + product mod 3 == 0
  of 6: (product mod 2 + product mod 3) mod 2 == 0
  else: ((x + y) mod 2 + product mod 3) mod 2 == 0

proc addFormat(candidate: var array[QrCells, uint8], mask: int) =
  let data = uint32(8 or mask)
  var remainder = data shl 10
  for bit in countdown(14, 10):
    if (remainder and (1'u32 shl bit)) != 0: remainder = remainder xor (0x537'u32 shl (bit - 10))
  let word = ((data shl 10) or remainder) xor 0x5412'u32
  for bit in 0 ..< 6: candidate[bit * QrSide + 8] = uint8((word shr bit) and 1)
  candidate[7 * QrSide + 8] = uint8((word shr 6) and 1)
  candidate[8 * QrSide + 8] = uint8((word shr 7) and 1)
  candidate[8 * QrSide + 7] = uint8((word shr 8) and 1)
  for bit in 9 ..< 15: candidate[8 * QrSide + 14 - bit] = uint8((word shr bit) and 1)
  for bit in 0 ..< 8: candidate[8 * QrSide + QrSide - 1 - bit] = uint8((word shr bit) and 1)
  for bit in 8 ..< 15: candidate[(QrSide - 15 + bit) * QrSide + 8] = uint8((word shr bit) and 1)
  candidate[(QrSide - 8) * QrSide + 8] = 1

proc penalty(matrix: array[QrCells, uint8]): uint32 =
  var score: uint32 = 0
  var dark: uint32 = 0
  for value in matrix: dark += uint32(value)
  for axis in 0 ..< 2:
    for line in 0 ..< QrSide:
      var run = 1
      for step in 1 ..< QrSide:
        let a = if axis == 1: matrix[step * QrSide + line] else: matrix[line * QrSide + step]
        let b = if axis == 1: matrix[(step - 1) * QrSide + line] else: matrix[line * QrSide + step - 1]
        if a == b: inc run
        else:
          if run >= 5: score += uint32(run - 2)
          run = 1
      if run >= 5: score += uint32(run - 2)
      for start in 0 .. QrSide - 11:
        var pattern: uint16 = 0
        for j in 0 ..< 11:
          let value = if axis == 1: matrix[(start + j) * QrSide + line] else: matrix[line * QrSide + start + j]
          pattern = (pattern shl 1) or uint16(value)
        if pattern == 0x05D or pattern == 0x5D0: score += 40
  for y in 0 .. QrSide - 2:
    for x in 0 .. QrSide - 2:
      let value = matrix[y * QrSide + x]
      if value == matrix[y * QrSide + x + 1] and
          value == matrix[(y + 1) * QrSide + x] and
          value == matrix[(y + 1) * QrSide + x + 1]: score += 3
  let total = uint32(QrCells)
  score += (if dark * 20 > total * 10: dark * 20 - total * 10 else: total * 10 - dark * 20) div total * 10
  score

proc evaluateMasks(frame, reserved: array[QrCells, uint8]): int =
  var bestScore = high(uint32)
  var bestMask = 0
  for mask in 0 ..< 8:
    var candidate = frame
    for i in 0 ..< QrCells:
      if reserved[i] == 0 and maskedBy(mask, i mod QrSide, i div QrSide): candidate[i] = candidate[i] xor 1
    addFormat(candidate, mask)
    let score = penalty(candidate)
    if score < bestScore:
      bestScore = score
      bestMask = mask
  bestMask

proc qrduino*(input: ptr UncheckedArray[int64], inputLength: csize_t,
              output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
              {.cdecl, exportc: "qrduino".} =
  if input.isNil or inputLength < 2 or inputLength > csize_t(MaxMessage + 2): return -1
  if input[0] < 1 or input[0] > int64(MaxMessage) or inputLength != csize_t(input[0] + 1): return -1
  let messageLength = int(input[0])
  var message: array[MaxMessage, uint8]
  for i in 0 ..< messageLength:
    if input[i + 1] < 1 or input[i + 1] > 127: return -1
    message[i] = uint8(input[i + 1])
  if output.isNil or outputCapacity < csize_t(PrefixBytes): return -2
  var words: array[DataWords + EccWords, uint8]
  var frame: array[QrCells, uint8]
  var reserved: array[QrCells, uint8]
  var staged: array[PrefixBytes, uint8]
  makeCodewords(message, messageLength, words)
  baseFrame(frame, reserved)
  placeData(frame, reserved, words)
  for y in 0 ..< 6:
    for x in 0 ..< QrSide:
      let byteIndex = y * 4 + x div 8
      if byteIndex < PrefixBytes and frame[y * QrSide + x] != 0:
        staged[byteIndex] = staged[byteIndex] or uint8(0x80 shr (x mod 8))
  discard evaluateMasks(frame, reserved)
  for i in 0 ..< PrefixBytes: output[i] = staged[i]
  int64(PrefixBytes)
