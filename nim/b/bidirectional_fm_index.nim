const MaxText = 64
const MaxTotal = 65

type Index = object
  cumulative: array[5, int]
  bwt: array[MaxTotal, int64]

proc suffixLess(s: ptr UncheckedArray[int64], total, a0, b0: int): bool =
  var a = a0
  var b = b0
  while a < total and b < total:
    if s[a] != s[b]: return s[a] < s[b]
    inc a
    inc b
  a == total and b != total

proc buildIndex(s: ptr UncheckedArray[int64], total: int): Index =
  var built: Index
  var suffixes: array[MaxTotal, int]
  var frequency: array[5, int]
  for i in 0 ..< total: suffixes[i] = i
  for i in 1 ..< total:
    let key = suffixes[i]
    var j = i
    while j > 0 and suffixLess(s, total, key, suffixes[j - 1]):
      suffixes[j] = suffixes[j - 1]
      dec j
    suffixes[j] = key
  for i in 0 ..< total:
    built.bwt[i] = s[(suffixes[i] + total - 1) mod total]
    inc frequency[int(built.bwt[i])]
  var seen = 0
  for symbol in 0 ..< 5:
    built.cumulative[symbol] = seen
    seen += frequency[symbol]
  built

proc rankBefore(index: Index, endAt, symbol: int): int =
  var count = 0
  for i in 0 ..< endAt:
    if int(index.bwt[i]) == symbol: inc count
  count

proc bidirectional_fm_index*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "bidirectional_fm_index".} =
  if input == nil or length < 2 or length > 195: return -1
  let n64 = input[0]
  let q64 = input[1]
  if n64 < 0 or n64 > int64(MaxText) or q64 < 0 or q64 > 64: return -1
  let n = int(n64)
  let q = int(q64)
  if length != csize_t(2 + n + 2 * q): return -1
  var forwardText, reverseText: array[MaxTotal, int64]
  for i in 0 ..< n:
    let symbol = input[2 + i]
    if symbol < 1 or symbol > 4: return -1
    forwardText[i] = symbol
    reverseText[n - 1 - i] = symbol
  forwardText[n] = 0
  reverseText[n] = 0
  for op in 0 ..< q:
    let side = input[2 + n + 2 * op]
    let symbol = input[3 + n + 2 * op]
    if (side != 0 and side != 1) or symbol < 1 or symbol > 4: return -1

  let total = n + 1
  let forward = buildIndex(cast[ptr UncheckedArray[int64]](addr forwardText[0]), total)
  let reverse = buildIndex(cast[ptr UncheckedArray[int64]](addr reverseText[0]), total)
  var fl = 0
  var fr = total
  var rl = 0
  var rr = total
  var checksum: int64 = 0
  for op in 0 ..< q:
    let side = int(input[2 + n + 2 * op])
    let symbol = int(input[3 + n + 2 * op])
    let oldFl = fl
    let oldFr = fr
    let oldRl = rl
    let oldRr = rr
    if side == 0:
      fl = forward.cumulative[symbol] + rankBefore(forward, oldFl, symbol)
      fr = forward.cumulative[symbol] + rankBefore(forward, oldFr, symbol)
      var start = oldRl
      for smaller in 0 ..< symbol:
        start += rankBefore(forward, oldFr, smaller) - rankBefore(forward, oldFl, smaller)
      let count = rankBefore(forward, oldFr, symbol) - rankBefore(forward, oldFl, symbol)
      rl = start
      rr = start + count
    else:
      rl = reverse.cumulative[symbol] + rankBefore(reverse, oldRl, symbol)
      rr = reverse.cumulative[symbol] + rankBefore(reverse, oldRr, symbol)
      var start = oldFl
      for smaller in 0 ..< symbol:
        start += rankBefore(reverse, oldRr, smaller) - rankBefore(reverse, oldRl, smaller)
      let count = rankBefore(reverse, oldRr, symbol) - rankBefore(reverse, oldRl, symbol)
      fl = start
      fr = start + count
    checksum += int64(op + 1) * int64(fr - fl)
  checksum
