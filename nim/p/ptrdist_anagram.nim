## Anagram program by Raymond Chen, inspired by a similar program by Brian Scearce.
## This program is Copyright 1991 by Raymond Chen. (rjc@math.princeton.edu)
## This program may be freely distributed provided all alterations to the original are clearly indicated as such.
## Alterations: bounded packed-array input, portable 64-bit packed counts, and a scalar decomposition count.

const MaxPhrase = 16
const MaxWords = 12
const MaxWordLength = 16
const Alphabet = 26

type
  Candidate = object
    mask: uint64
    length: int
  Search = object
    candidates: array[MaxWords, Candidate]
    candidateCount: int
    order: array[Alphabet, int]
    letterMask: array[Alphabet, uint64]
    signMask: uint64

proc letterIndex(value: int64): int =
  if value >= 97 and value <= 122: return int(value - 97)
  if value >= 65 and value <= 90: return int(value - 65)
  -1

proc findAnagrams(search: var Search, remainingMask: uint64, remainingLength, startValue, firstLetter: int): int64 =
  if remainingLength == 0: return 1
  var pivotPosition = firstLetter
  while pivotPosition < Alphabet:
    let letter = search.order[pivotPosition]
    if (remainingMask and search.letterMask[letter]) != 0: break
    inc pivotPosition
  if pivotPosition == Alphabet: return 0
  let pivot = search.order[pivotPosition]
  var start = startValue
  var ending = search.candidateCount
  while start < ending:
    let candidate = search.candidates[start]
    let after = remainingMask - candidate.mask
    if (after and search.signMask) != 0:
      inc start
      continue
    if (candidate.mask and search.letterMask[pivot]) == 0:
      search.candidates[start] = search.candidates[ending - 1]
      search.candidates[ending - 1] = candidate
      dec ending
      continue
    let nextLength = remainingLength - candidate.length
    result += (if nextLength == 0: 1'i64 else: findAnagrams(search, after, nextLength, start, pivotPosition))
    inc start

proc ptrdist_anagram*(input: ptr int64, length: csize_t): int64 {.cdecl, exportc: "ptrdist_anagram".} =
  if input == nil or length < 3 or length > 222: return -1
  let values = cast[ptr UncheckedArray[int64]](input)
  if values[0] < 1 or values[0] > int64(MaxPhrase): return -1
  let phraseLength = int(values[0])
  let countOffset = phraseLength + 1
  if csize_t(countOffset) >= length or values[countOffset] < 0 or values[countOffset] > int64(MaxWords): return -1
  var phraseCounts: array[Alphabet, uint8]
  for i in 0 ..< phraseLength:
    let letter = letterIndex(values[i + 1])
    if letter < 0: return -1
    inc phraseCounts[letter]

  let wordCount = int(values[countOffset])
  var offset = countOffset + 1
  var phraseMask = 0'u64
  var signMask = 0'u64
  var letterMask: array[Alphabet, uint64]
  var letterShift: array[Alphabet, uint32]
  var globalFrequency: array[Alphabet, uint32]
  var shift = 0'u32
  for letter in 0 ..< Alphabet:
    let frequency = uint32(phraseCounts[letter])
    if frequency == 0: continue
    var countBits = 1'u32
    while (1'u32 shl countBits) <= frequency: inc countBits
    if shift + countBits + 1 > 64: return -1
    letterMask[letter] = ((1'u64 shl countBits) - 1) shl shift
    phraseMask = phraseMask or (uint64(frequency) shl shift)
    signMask = signMask or (1'u64 shl (shift + countBits))
    letterShift[letter] = shift
    shift += countBits + 1

  var search: Search
  search.signMask = signMask
  search.letterMask = letterMask
  for _ in 0 ..< wordCount:
    if csize_t(offset) >= length or values[offset] < 1 or values[offset] > int64(MaxWordLength): return -1
    let wordLength = int(values[offset])
    inc offset
    if csize_t(wordLength) > length - csize_t(offset): return -1
    var counts: array[Alphabet, uint8]
    for i in 0 ..< wordLength:
      let letter = letterIndex(values[offset + i])
      if letter < 0: return -1
      inc counts[letter]
    var fits = true
    for letter in 0 ..< Alphabet:
      if counts[letter] > phraseCounts[letter]: fits = false
    if fits and ((wordLength >= 2 and wordLength + 2 <= phraseLength) or wordLength == phraseLength):
      var mask = 0'u64
      for letter in 0 ..< Alphabet:
        mask = mask or (uint64(counts[letter]) shl letterShift[letter])
        globalFrequency[letter] += uint32(counts[letter])
      search.candidates[search.candidateCount] = Candidate(mask: mask, length: wordLength)
      inc search.candidateCount
    offset += wordLength
  if csize_t(offset) != length: return -1

  for letter in 0 ..< Alphabet: search.order[letter] = letter
  for i in 1 ..< Alphabet:
    let key = search.order[i]
    var j = i
    while j > 0:
      let previous = search.order[j - 1]
      let previousFrequency = if globalFrequency[previous] == 0: high(uint32) else: globalFrequency[previous]
      let keyFrequency = if globalFrequency[key] == 0: high(uint32) else: globalFrequency[key]
      if previousFrequency < keyFrequency or (previousFrequency == keyFrequency and previous < key): break
      search.order[j] = previous
      dec j
    search.order[j] = key
  findAnagrams(search, phraseMask, phraseLength, 0, 0)
