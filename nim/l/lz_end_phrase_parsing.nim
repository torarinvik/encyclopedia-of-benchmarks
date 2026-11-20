const MaxText = 64
const MaxInput = 66
const PhraseMultiplier = 133121'i64

proc lz_end_phrase_parsing*(input: ptr UncheckedArray[int64], len: csize_t): int64 {.cdecl, exportc: "lz_end_phrase_parsing".} =
  if input.isNil or len < 1 or len > csize_t(MaxInput): return -1
  let n64 = input[0]
  if n64 < 0 or n64 > MaxText or len != csize_t(n64 + 1): return -1
  let n = int(n64)
  for i in 0..<n:
    if input[i + 1] < 0 or input[i + 1] > 255: return -1
  var boundaries: array[MaxText, int]
  var phraseLengths: array[MaxText, int]
  var phrases = 0
  var position = 0
  while position < n:
    var bestCopy = 0
    var copyLength = n - position - 1
    while copyLength > 0 and bestCopy == 0:
      var prior = phrases - 1
      while prior >= 0 and bestCopy == 0:
        let boundary = boundaries[prior]
        if boundary >= copyLength:
          var matches = true
          for offset in 0..<copyLength:
            if input[1 + position + offset] != input[1 + boundary - copyLength + offset]:
              matches = false
              break
          if matches: bestCopy = copyLength
        dec prior
      dec copyLength
    phraseLengths[phrases] = bestCopy + 1
    position += phraseLengths[phrases]
    boundaries[phrases] = position
    inc phrases
  var checksum = 0'i64
  for i in 0..<phrases: checksum += int64(i + 1) * int64(phraseLengths[i])
  PhraseMultiplier * int64(phrases) + checksum
