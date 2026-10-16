import std/algorithm

const maxLength = 256
const minValue = -1_000_000'i64
const maxValue = 1_000_000'i64
const checksumOffset = 1_000_001'i64

proc sort_the_odd_benchmark*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "sort_the_odd_benchmark".} =
  if length > csize_t(maxLength) or (input == nil and length != 0): return -1

  var odds: seq[int64] = @[]
  for i in 0 ..< int(length):
    let value = input[i]
    if value < minValue or value > maxValue: return -1
    if value mod 2 != 0: odds.add(value)
  odds.sort()

  var oddIndex = 0
  var checksum = 0'i64
  for i in 0 ..< int(length):
    var value = input[i]
    if value mod 2 != 0:
      value = odds[oddIndex]
      inc oddIndex
    checksum += int64(i + 1) * (value + checksumOffset)
  return checksum
