# Clean-room completion-count dynamic programming for Dyck-word rank/unrank.
import std/posix

const MaxPairs = 10
const MaxInputLength = 22
const WaysStride = 11
const WaysCount = 231

proc balanced_parenthesis_rank_unrank*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "balanced_parenthesis_rank_unrank".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInputLength): return -1
  let mode = input[0]
  let pairValue = input[1]
  if pairValue < 1 or pairValue > MaxPairs.int64: return -1
  let pairs = int(pairValue)
  let sequenceLength = 2 * pairs
  if mode == 0:
    if int64(length) != 2 + sequenceLength: return -1
    var balance = 0
    for i in 0..<sequenceLength:
      let symbol = input[2 + i]
      if symbol != 0 and symbol != 1: return -1
      if symbol == 0: inc balance
      else: dec balance
      if balance < 0: return -1
    if balance != 0: return -1
  elif mode == 1:
    if length != csize_t(3): return -1
  else:
    return -1

  var ways: array[WaysCount, int64]
  ways[0] = 1
  for remaining in 1..sequenceLength:
    for balance in 0..pairs:
      var count = 0'i64
      if balance < pairs: count += ways[(remaining - 1) * WaysStride + balance + 1]
      if balance > 0: count += ways[(remaining - 1) * WaysStride + balance - 1]
      ways[remaining * WaysStride + balance] = count

  if mode == 0:
    var rank = 0'i64
    var balance = 0
    for i in 0..<sequenceLength:
      let symbol = input[2 + i]
      let remaining = sequenceLength - i - 1
      if symbol == 1 and balance < pairs: rank += ways[remaining * WaysStride + balance + 1]
      if symbol == 0: inc balance
      else: dec balance
    return rank

  var rank = input[2]
  if rank < 0 or rank >= ways[sequenceLength * WaysStride]: return -1
  var balance = 0
  var code = 0'i64
  for i in 0..<sequenceLength:
    let remaining = sequenceLength - i - 1
    let openingCount = if balance < pairs: ways[remaining * WaysStride + balance + 1] else: 0'i64
    var symbol = 0'i64
    if rank < openingCount: inc balance
    else:
      rank -= openingCount
      symbol = 1
      dec balance
    code = (code shl 1) or symbol
  code
