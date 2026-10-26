proc suffixLess(s: ptr UncheckedArray[int64], n, a0, b0: int): bool =
  var a = a0
  var b = b0
  while a < n and b < n:
    if s[a] != s[b]: return s[a] < s[b]
    inc a; inc b
  a == n and b != n

proc fm_index_count*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "fm_index_count".} =
  const MaxText = 32
  const MaxPattern = 8
  if input == nil or length < 4 or length > 42: return -1
  if input[0] < 1 or input[0] > MaxText or length < csize_t(input[0] + 3): return -1
  let n = int(input[0]); let mAt = n + 1; let m64 = input[mAt]
  if m64 < 1 or m64 > MaxPattern or length != csize_t(n + int(m64) + 2): return -1
  let m = int(m64); let total = n + 1
  var s: array[MaxText + 1, int64]
  var pattern: array[MaxPattern, int64]
  for i in 0 ..< n:
    if input[1+i] < 1 or input[1+i] > 4: return -1
    s[i] = input[1+i]
  for i in 0 ..< m:
    if input[mAt+1+i] < 1 or input[mAt+1+i] > 4: return -1
    pattern[i] = input[mAt+1+i]
  s[n] = 0
  if output == nil or outputCapacity < 8: return -2
  var sa: array[MaxText + 1, int]
  for i in 0 ..< total: sa[i] = i
  for i in 1 ..< total:
    let key = sa[i]
    var j = i
    while j > 0 and suffixLess(addr s[0], total, key, sa[j-1]):
      sa[j] = sa[j-1]; dec j
    sa[j] = key
  var bwt: array[MaxText + 1, int]
  var freq: array[5, int]
  for i in 0 ..< total:
    bwt[i] = int(s[(sa[i] + total - 1) mod total])
    inc freq[bwt[i]]
  var c: array[5, int]
  var sum = 0
  for x in 0 ..< 5: c[x] = sum; sum += freq[x]
  var left = 0; var right = total
  for k in countdown(m-1, 0):
    let symbol = int(pattern[k]); var rl = 0; var rr = 0
    for i in 0 ..< left: if bwt[i] == symbol: inc rl
    for i in 0 ..< right: if bwt[i] == symbol: inc rr
    left = c[symbol] + rl; right = c[symbol] + rr
    if left == right: break
  let count = uint64(right-left)
  for i in 0 ..< 8: output[i] = uint8((count shr (8*i)) and 0xff'u64)
  8
