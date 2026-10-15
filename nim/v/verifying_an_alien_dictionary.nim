const MaxWords = 100
const MaxInputLength = 2127
const InvalidResult = -1'i64

proc verifying_an_alien_dictionary*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "verifying_an_alien_dictionary".} =
  if input.isNil or length < 27 or length > MaxInputLength or input[0] < 1 or input[0] > MaxWords:
    return InvalidResult
  let wordCount = int(input[0])
  var rank: array[26, int64]
  var orderSeen: array[26, bool]
  for position in 0 ..< 26:
    let letter = input[1 + position]
    if letter < int64(ord('a')) or letter > int64(ord('z')): return InvalidResult
    let index = int(letter - int64(ord('a')))
    if orderSeen[index]: return InvalidResult
    orderSeen[index] = true
    rank[index] = int64(position)

  var starts: array[MaxWords, int]
  var wordLengths: array[MaxWords, int]
  var offset = 27
  for word in 0 ..< wordCount:
    if offset >= int(length) or input[offset] < 1 or input[offset] > 20: return InvalidResult
    let wordLength = int(input[offset])
    inc offset
    if wordLength > int(length) - offset: return InvalidResult
    starts[word] = offset
    wordLengths[word] = wordLength
    for character in 0 ..< wordLength:
      let letter = input[offset + character]
      if letter < int64(ord('a')) or letter > int64(ord('z')): return InvalidResult
    offset += wordLength
  if offset != int(length): return InvalidResult

  for word in 0 ..< (wordCount - 1):
    let leftLength = wordLengths[word]
    let rightLength = wordLengths[word + 1]
    let limit = min(leftLength, rightLength)
    var decided = false
    for character in 0 ..< limit:
      let leftLetter = int(input[starts[word] + character] - int64(ord('a')))
      let rightLetter = int(input[starts[word + 1] + character] - int64(ord('a')))
      if rank[leftLetter] < rank[rightLetter]:
        decided = true
        break
      if rank[leftLetter] > rank[rightLetter]: return 0
    if not decided and leftLength > rightLength: return 0
  1
