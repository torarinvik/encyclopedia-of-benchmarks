const MAX_WORDS = 8
const MAX_PATH_WORDS = MAX_WORDS + 1
const MAX_INPUT_LENGTH = 4 + MAX_WORDS
const MAX_OUTPUT_FIELDS = MAX_PATH_WORDS + MAX_WORDS + 2

proc powerOf26(exponent: int): int64 =
  var result = 1'i64
  for _ in 0 ..< exponent: result *= 26
  result

proc findActiveWord(words: ptr UncheckedArray[int64], active: var array[MAX_WORDS, uint8],
                    count: int, candidate: int64): int =
  for index in 0 ..< count:
    if active[index] != 0'u8 and words[4 + index] == candidate: return index
  count

proc backtrack(current, target: int64, width: int, words: ptr UncheckedArray[int64],
               count: int, active: var array[MAX_WORDS, uint8],
               path: var array[MAX_PATH_WORDS, int64], pathLength: var int): bool =
  if current == target: return true
  for position in 0 ..< width:
    let factor = powerOf26(width - position - 1)
    let digit = (current div factor) mod 26
    for replacement in 0 ..< 26:
      let candidate = current + (int64(replacement) - digit) * factor
      let index = findActiveWord(words, active, count, candidate)
      if index == count: continue
      active[index] = 0'u8
      path[pathLength] = candidate
      inc pathLength
      if backtrack(candidate, target, width, words, count, active, path, pathLength): return true
      dec pathLength
      active[index] = 1'u8
  false

proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc word_ladder_dfs*(input: ptr UncheckedArray[int64], length: csize_t,
                      output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "word_ladder_dfs".} =
  if input.isNil or length < 4 or length > MAX_INPUT_LENGTH: return -1
  let widthValue = input[0]
  let beginWord = input[1]
  let endWord = input[2]
  let countValue = input[3]
  if widthValue < 1 or widthValue > 5 or countValue < 0 or countValue > MAX_WORDS or
      length != 4 + countValue: return -1
  let width = int(widthValue)
  let count = int(countValue)
  let limit = powerOf26(width)
  if beginWord < 0 or beginWord >= limit or endWord < 0 or endWord >= limit: return -1
  for index in 0 ..< count:
    if input[4 + index] < 0 or input[4 + index] >= limit or
        (index > 0 and input[3 + index] >= input[4 + index]): return -1

  var active: array[MAX_WORDS, uint8]
  for index in 0 ..< count: active[index] = 1'u8
  var path: array[MAX_PATH_WORDS, int64]
  path[0] = beginWord
  var pathLength = 1
  if findActiveWord(input, active, count, endWord) != count:
    if not backtrack(beginWord, endWord, width, input, count, active, path, pathLength):
      pathLength = 0
  else:
    pathLength = 0

  var fields: array[MAX_OUTPUT_FIELDS, int64]
  var fieldCount = 0
  fields[fieldCount] = int64(pathLength); inc fieldCount
  for index in 0 ..< pathLength: fields[fieldCount] = path[index]; inc fieldCount
  var remaining = 0
  for index in 0 ..< count:
    if active[index] != 0'u8: inc remaining
  fields[fieldCount] = int64(remaining); inc fieldCount
  for index in 0 ..< count:
    if active[index] != 0'u8: fields[fieldCount] = input[4 + index]; inc fieldCount
  let required = fieldCount * 8
  if output.isNil or capacity < required: return -2
  for index in 0 ..< fieldCount: writeI64Le(output, index * 8, fields[index])
  int64(required)
