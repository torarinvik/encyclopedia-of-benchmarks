const MaxText = 32
const MaxInput = 34
const MaxOutput = 512

proc suffixLess(text: ptr UncheckedArray[int64], n, a0, b0: int): bool =
  var a = a0
  var b = b0
  while a < n and b < n:
    if text[a] != text[b]: return text[a] < text[b]
    inc a
    inc b
  a == n and b != n

proc lcp(text: ptr UncheckedArray[int64], n: int, source: int64, target: int): int =
  if source < 0: return 0
  var p = int(source)
  while target + result < n and text[p + result] == text[target + result]: inc result

proc put64(outp: ptr UncheckedArray[uint8], at: int, value: int64) =
  let bits = cast[uint64](value)
  for i in 0..<8: outp[at+i] = uint8((bits shr (8*i)) and 255)

proc lz77_lpf_suffix_array*(input: ptr UncheckedArray[int64], len: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "lz77_lpf_suffix_array".} =
  if input.isNil or len < 1 or len > csize_t(MaxInput): return -1
  let n64 = input[0]
  if n64 < 0 or n64 > MaxText: return -1
  let n = int(n64)
  if len != csize_t(n+1): return -1
  var text: array[MaxText, int64]
  for i in 0..<n:
    if input[i+1] < 0 or input[i+1] > 255: return -1
    text[i] = input[i+1]
  var sa, inverse, stack: array[MaxText, int]
  var previous, following: array[MaxText, int]
  for i in 0..<n:
    sa[i] = i
    previous[i] = -1
    following[i] = -1
  for i in 1..<n:
    let value = sa[i]
    var j = i
    while j > 0 and suffixLess(addr text[0], n, value, sa[j-1]):
      sa[j] = sa[j-1]
      dec j
    sa[j] = value
  for rank in 0..<n: inverse[sa[rank]] = rank
  var top = 0
  for rank in 0..<n:
    while top > 0 and sa[stack[top-1]] > sa[rank]: dec top
    if top > 0: previous[rank] = stack[top-1]
    stack[top] = rank
    inc top
  top = 0
  var rr = n
  while rr > 0:
    dec rr
    while top > 0 and sa[stack[top-1]] > sa[rr]: dec top
    if top > 0: following[rr] = stack[top-1]
    stack[top] = rr
    inc top
  var staged: array[MaxOutput, uint8]
  var pairs = 0
  var pos = 0
  while pos < n:
    let rank = inverse[pos]
    let psv = if previous[rank] >= 0: int64(sa[previous[rank]]) else: -1'i64
    let nsv = if following[rank] >= 0: int64(sa[following[rank]]) else: -1'i64
    let lp = lcp(addr text[0], n, psv, pos)
    let ln = lcp(addr text[0], n, nsv, pos)
    var source = if ln > lp: nsv else: psv
    let matched = if ln > lp: ln else: lp
    if matched == 0: source = -1
    put64(addr staged[0], pairs*16, source)
    put64(addr staged[0], pairs*16+8, int64(matched))
    inc pairs
    pos += (if matched > 0: matched else: 1)
  let bytes = pairs*16
  if output.isNil or capacity < csize_t(bytes): return -2
  for i in 0..<bytes: output[i] = staged[i]
  int64(bytes)
