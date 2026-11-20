const MaxCards = 12
const MaxInputWords = 14
const DeckSize = 81

type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc complementCode(aRaw, bRaw: int8): int =
  let a = int(aRaw)
  let b = int(bRaw)
  var place = 1
  var resultCode = 0
  for _ in 0 ..< 4:
    let digitSum = (a div place) mod 3 + (b div place) mod 3
    resultCode += ((3 - digitSum mod 3) mod 3) * place
    place *= 3
  resultCode

proc putI64Le(output: U8Output, word: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[word * 8 + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc set_puzzle_find_sets*(input: I64Input, length: csize_t, output: U8Output,
    capacity: csize_t): int64 {.cdecl, exportc: "set_puzzle_find_sets".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputWords): return -1
  let rawCount = input[0]
  if rawCount < 0 or rawCount > int64(MaxCards) or length != csize_t(rawCount + 1): return -1

  var indexByCode: array[DeckSize, int8]
  var codeByIndex: array[MaxCards, int8]
  for code in 0 ..< DeckSize: indexByCode[code] = -1
  let count = int(rawCount)
  for i in 0 ..< count:
    let code = input[i + 1]
    if code < 0 or code >= int64(DeckSize): return -1
    if indexByCode[int(code)] >= 0: return -1
    indexByCode[int(code)] = int8(i)
    codeByIndex[i] = int8(code)

  var setCount = 0
  for i in 0 ..< count:
    for j in i + 1 ..< count:
      let k = indexByCode[complementCode(codeByIndex[i], codeByIndex[j])]
      if k > int8(j): inc setCount
  let outputBytes = (1 + 3 * setCount) * 8
  if output.isNil or capacity < csize_t(outputBytes): return -2

  putI64Le(output, 0, int64(setCount))
  var word = 1
  for i in 0 ..< count:
    for j in i + 1 ..< count:
      let k = indexByCode[complementCode(codeByIndex[i], codeByIndex[j])]
      if k > int8(j):
        putI64Le(output, word, int64(i))
        putI64Le(output, word + 1, int64(j))
        putI64Le(output, word + 2, int64(k))
        word += 3
  int64(outputBytes)
