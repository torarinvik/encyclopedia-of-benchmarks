import std/strutils

const etaoin = "ETAOINSHRDLCUMWFGYPBVKJXQZ"

proc frequency_finder*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "frequency_finder".} =
  if input == nil:
    if length == 0: return 0
    return -1
  if length > 1024: return -1
  var counts: array[26, int64]
  for i in 0 ..< int(length):
    var b = input[i]
    if b < 0 or b > 127: return -1
    if b >= 97 and b <= 122: b -= 32
    if b >= 65 and b <= 90: inc counts[int(b - 65)]
  var order: array[26, int]
  for i in 0 ..< 26: order[i] = i
  for i in 1 ..< 26:
    let key = order[i]
    let kr = etaoin.find(chr(65 + key))
    var j = i
    while j > 0:
      let p = order[j - 1]
      let pr = etaoin.find(chr(65 + p))
      if counts[p] > counts[key] or (counts[p] == counts[key] and pr > kr): break
      order[j] = p; dec j
    order[j] = key
  var score = 0'i64
  for i in 0 ..< 6:
    for j in 0 ..< 6:
      if chr(65 + order[i]) == etaoin[j]: inc score; break
    for j in 20 ..< 26:
      if chr(65 + order[20 + i]) == etaoin[j]: inc score; break
  return score
