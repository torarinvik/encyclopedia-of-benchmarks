# Fresh bounded port based on NyaanNyaan's CC0 radix-2 Schönhage-Strassen method.
const LimbCount = 513
const Padded = 2048
const ScratchSize = 4096
const OutputBytes = 129

type I64Buffer = ptr UncheckedArray[int64]

proc plus(p: I64Buffer, index: int): I64Buffer =
  cast[I64Buffer](cast[uint](p) + uint(index * sizeof(int64)))

proc ssZero(a: I64Buffer, n: int) =
  for i in 0 ..< n: a[i] = 0

proc ssCopy(dst, src: I64Buffer, n: int) =
  for i in 0 ..< n: dst[i] = src[i]

proc ssAdd(dst, src: I64Buffer, n: int) =
  for i in 0 ..< n: dst[i] += src[i]

proc ssSub(dst, src: I64Buffer, n: int) =
  for i in 0 ..< n: dst[i] -= src[i]

proc ssRot(dst, src: I64Buffer, size, shift: int) =
  var d = shift
  let wrapped = d >= size
  if wrapped: d -= size
  var i = 0
  if wrapped:
    while i < size - d:
      dst[i + d] = -src[i]
      inc i
    while i < size:
      dst[i + d - size] = src[i]
      inc i
  else:
    while i < size - d:
      dst[i + d] = src[i]
      inc i
    while i < size:
      dst[i + d - size] = -src[i]
      inc i

proc ssCtz(value: uint): int =
  var x = value
  result = 0
  while (x and 1'u) == 0:
    inc result
    x = x shr 1

proc ssFft(a: I64Buffer, l, m: int, buf: I64Buffer) =
  if l == 0: return
  let len = 1 shl l
  let blockSize = 1 shl m
  var dw: array[16, int]
  for i in 0 ..< (l - 1):
    dw[i] = (1 shl (l - 2 - i)) + (1 shl (l - 1 - i)) - (1 shl (l - 1))
    if dw[i] < 0: dw[i] += len
    if len == blockSize: dw[i] *= 2
    if 2 * len == blockSize: dw[i] *= 4
  var d = len div 2
  while d > 0:
    var w = 0
    var s = 0
    var k = 0
    while true:
      for i in s ..< s + d:
        let ai = plus(a, i * blockSize)
        let aj = plus(a, (i + d) * blockSize)
        ssRot(buf, aj, blockSize, w)
        ssCopy(aj, ai, blockSize)
        ssAdd(ai, buf, blockSize)
        ssSub(aj, buf, blockSize)
      s += 2 * d
      if s >= len: break
      inc k
      w += dw[ssCtz(uint(k))]
      if w >= 2 * blockSize: w -= 2 * blockSize
    d = d div 2

proc ssIfft(a: I64Buffer, l, m: int, buf: I64Buffer) =
  if l == 0: return
  let len = 1 shl l
  let blockSize = 1 shl m
  var dw: array[16, int]
  for i in 0 ..< (l - 1):
    dw[i] = (1 shl (l - 2 - i)) + (1 shl (l - 1 - i)) - (1 shl (l - 1))
    if dw[i] < 0: dw[i] += len
    if len == blockSize: dw[i] *= 2
    if 2 * len == blockSize: dw[i] *= 4
  var d = 1
  while d < len:
    var w = 0
    var s = 0
    var k = 0
    while true:
      for i in s ..< s + d:
        let ai = plus(a, i * blockSize)
        let aj = plus(a, (i + d) * blockSize)
        ssCopy(buf, ai, blockSize)
        ssAdd(ai, aj, blockSize)
        ssSub(buf, aj, blockSize)
        ssRot(aj, buf, blockSize, w)
      s += 2 * d
      if s >= len: break
      inc k
      w -= dw[ssCtz(uint(k))]
      if w < 0: w += 2 * blockSize
    d *= 2

proc ssNaive(a, b: I64Buffer, n: int, buf: I64Buffer) =
  let size = 1 shl n
  ssZero(buf, size)
  for i in 0 ..< size:
    var j = 0
    while j < size - i:
      buf[i + j] += a[i] * b[j]
      inc j
    while j < size:
      buf[i + j - size] -= a[i] * b[j]
      inc j
  ssCopy(a, buf, size)

proc ssMul(a, b: I64Buffer, n: int, buf: I64Buffer) =
  if n <= 5:
    ssNaive(a, b, n, buf)
    return
  let l = (n + 1) div 2
  let m = n div 2
  let len = 1 shl l
  let blockSize = 1 shl m
  var aa, bb: array[ScratchSize, int64]
  let ap = cast[I64Buffer](addr aa[0])
  let bp = cast[I64Buffer](addr bb[0])
  ssZero(ap, ScratchSize); ssZero(bp, ScratchSize); ssZero(plus(buf, blockSize), blockSize)
  for i in 0 ..< len:
    ssCopy(buf, plus(a, i * blockSize), blockSize)
    ssRot(plus(ap, i * blockSize * 2), buf, blockSize * 2, i * (2 * blockSize div len))
    ssCopy(buf, plus(b, i * blockSize), blockSize)
    ssRot(plus(bp, i * blockSize * 2), buf, blockSize * 2, i * (2 * blockSize div len))
  ssFft(ap, l, m + 1, buf); ssFft(bp, l, m + 1, buf)
  for i in 0 ..< len: ssMul(plus(ap, i * blockSize * 2), plus(bp, i * blockSize * 2), m + 1, buf)
  ssIfft(ap, l, m + 1, buf)
  for i in 0 ..< len:
    let s = i * (2 * blockSize div len)
    ssCopy(buf, plus(ap, i * blockSize * 2), blockSize * 2)
    ssRot(plus(ap, i * blockSize * 2), buf, blockSize * 2, s)
  for i in 0 ..< len:
    for j in 0 ..< blockSize:
      a[i * blockSize + j] = ap[i * blockSize * 2 + j]
      if i == 0: a[i * blockSize + j] -= ap[(len - 1) * blockSize * 2 + blockSize + j]
      else: a[i * blockSize + j] += ap[(i - 1) * blockSize * 2 + blockSize + j]

proc ssMulCyclic(a, b: I64Buffer, n: int, buf: I64Buffer) =
  if n <= 5:
    ssNaive(a, b, n, buf)
    return
  let l = (n + 1) div 2
  let m = n div 2
  let len = 1 shl l
  let blockSize = 1 shl m
  var aa, bb: array[ScratchSize, int64]
  let ap = cast[I64Buffer](addr aa[0])
  let bp = cast[I64Buffer](addr bb[0])
  ssZero(ap, ScratchSize); ssZero(bp, ScratchSize)
  for i in 0 ..< len:
    ssCopy(plus(ap, i * blockSize * 2), plus(a, i * blockSize), blockSize)
    ssCopy(plus(bp, i * blockSize * 2), plus(b, i * blockSize), blockSize)
  ssFft(ap, l, m + 1, buf); ssFft(bp, l, m + 1, buf)
  for i in 0 ..< len: ssMul(plus(ap, i * blockSize * 2), plus(bp, i * blockSize * 2), m + 1, buf)
  ssIfft(ap, l, m + 1, buf)
  for i in 0 ..< len:
    for j in 0 ..< blockSize:
      a[i * blockSize + j] = ap[i * blockSize * 2 + j] + ap[(if i == 0: len - 1 else: i - 1) * blockSize * 2 + blockSize + j]

proc schoenhage_strassen_multiply*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "schoenhage_strassen_multiply".} =
  if input.isNil or length != csize_t(1 + 2 * LimbCount) or input[0] != LimbCount: return -1
  var a, b, scratch: array[Padded, int64]
  for i in 0 ..< LimbCount:
    let x = input[1 + i]
    let y = input[1 + LimbCount + i]
    if x < 0 or x > 1 or y < 0 or y > 1: return -1
    a[i] = x; b[i] = y
  if a[LimbCount - 1] != 1 or b[LimbCount - 1] != 1: return -1
  if output.isNil or capacity < csize_t(OutputBytes): return -2
  ssMulCyclic(cast[I64Buffer](addr a[0]), cast[I64Buffer](addr b[0]), 11, cast[I64Buffer](addr scratch[0]))
  var encoded: array[OutputBytes, uint8]
  var carry = 0'i64
  for i in 0 ..< 1025:
    let value = a[i] + carry
    let bit = uint8(value mod 2)
    carry = value div 2
    if bit != 0: encoded[OutputBytes - 1 - i div 8] = encoded[OutputBytes - 1 - i div 8] or (bit shl (i mod 8))
  var bitIndex = 1025
  while carry > 0:
    if carry mod 2 != 0: encoded[OutputBytes - 1 - bitIndex div 8] = encoded[OutputBytes - 1 - bitIndex div 8] or uint8(1 shl (bitIndex mod 8))
    carry = carry div 2
    inc bitIndex
  for i in 0 ..< OutputBytes: output[i] = encoded[i]
  int64(OutputBytes)
