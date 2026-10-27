const MaxText = 32
const MaxInput = 36
const Alphabet = 5

proc suffixLess(text: openArray[int64], a0, b0: int): bool =
  var a = a0
  var b = b0
  while a < text.len and b < text.len:
    if text[a] != text[b]: return text[a] < text[b]
    inc a
    inc b
  a == text.len and b != text.len

proc fm_index_display*(input: ptr UncheckedArray[int64], length: csize_t,
                       output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "fm_index_display".} =
  if input.isNil or length < 5 or length > MaxInput: return -1
  let n0 = input[0]
  if n0 < 1 or n0 > MaxText or int(length) != int(n0) + 4: return -1
  let n = int(n0)
  let left0 = input[n + 1]
  let right0 = input[n + 2]
  let stride0 = input[n + 3]
  if left0 < 0 or right0 < left0 or right0 >= n0 or stride0 < 1 or stride0 > n0: return -1
  let left = int(left0)
  let right = int(right0)
  let stride = int(stride0)
  let size = n + 1
  var text: array[MaxText + 1, int64]
  for i in 0 ..< n:
    if input[i + 1] < 1 or input[i + 1] > 4: return -1
    text[i] = input[i + 1]
  text[n] = 0
  var sa: array[MaxText + 1, int]
  for i in 0 ..< size: sa[i] = i
  for i in 1 ..< size:
    let key = sa[i]
    var j = i
    while j > 0 and suffixLess(text.toOpenArray(0, size - 1), key, sa[j - 1]):
      sa[j] = sa[j - 1]
      dec j
    sa[j] = key
  var isa: array[MaxText + 1, int]
  var bwt: array[MaxText + 1, int]
  var frequencies: array[Alphabet, int]
  for row in 0 ..< size:
    let pos = sa[row]
    isa[pos] = row
    bwt[row] = int(text[(pos + size - 1) mod size])
    inc frequencies[bwt[row]]
  var first, seen: array[Alphabet, int]
  var total = 0
  for c in 0 ..< Alphabet:
    first[c] = total
    total += frequencies[c]
  var lf: array[MaxText + 1, int]
  for row in 0 ..< size:
    let symbol = bwt[row]
    lf[row] = first[symbol] + seen[symbol]
    inc seen[symbol]
  var sampledIsa: array[MaxText + 1, int]
  var sampled: array[MaxText + 1, bool]
  var pos = 0
  while pos < n:
    if (pos + 1) mod stride == 0:
      sampled[pos] = true
      sampledIsa[pos] = isa[pos]
    inc pos
  sampled[n] = true
  sampledIsa[n] = isa[n]
  var sample = ((right + 1) div stride + 1) * stride - 1
  if sample > n: sample = n
  if not sampled[sample]: return -1
  var row = sampledIsa[sample]
  var current = sample
  while current > right + 1:
    row = lf[row]
    dec current
  var reversed: array[MaxText, uint8]
  var count = 0
  while current > left:
    reversed[count] = uint8(bwt[row])
    inc count
    row = lf[row]
    dec current
  if count != right - left + 1: return -1
  if output.isNil or int(capacity) < count: return -2
  for i in 0 ..< count: output[i] = reversed[count - i - 1]
  int64(count)
