type
  InputWords = ptr UncheckedArray[int64]
  OutputBytes = ptr UncheckedArray[uint8]
  FixedValues = array[15, int64]

const
  Modulus = 998244353'i64
  MaxN = 64
  MaxQ = 15
  MaxParseable = 32

proc prefixValue(q, prefix: FixedValues, count: int, value: int64): int64 =
  if value == 0: return 0
  for i in 0 ..< count:
    if q[i] == value: return prefix[i]
  0

proc dirichlet_convolution_and_prefix_sums*(input: InputWords, length: csize_t,
    output: OutputBytes, outputCapacity: csize_t): int64
    {.cdecl, exportc: "dirichlet_convolution_and_prefix_sums".} =
  if input == nil or length < csize_t(3) or length > csize_t(MaxParseable): return -1
  let n = input[0]
  if n < 1 or n > int64(MaxN): return -1
  var descending: FixedValues
  var count = 0
  var left = 1'i64
  while left <= n:
    let value = n div left
    descending[count] = value
    inc count
    left = n div value + 1
  var q, f, g, answers: FixedValues
  for i in 0 ..< count: q[i] = descending[count - 1 - i]
  if length != csize_t(1 + 2 * count): return -1
  for i in 0 ..< count:
    f[i] = input[1 + i]
    g[i] = input[1 + count + i]
    if f[i] < 1 or f[i] >= Modulus or g[i] < 1 or g[i] >= Modulus: return -1
  let needed = 8 * count
  if output == nil or outputCapacity < csize_t(needed): return -2

  for outIndex in 0 ..< count:
    let x = q[outIndex]
    var total = 0'i64
    var start = 1'i64
    while start <= x:
      let quotient = x div start
      let right = x div quotient
      let below = x div (quotient + 1)
      var interval = (prefixValue(q, f, count, right) - prefixValue(q, f, count, below)) mod Modulus
      if interval < 0: interval += Modulus
      var qIndex = 0
      while qIndex < count and q[qIndex] != quotient: inc qIndex
      if qIndex == count: return -1
      total = (total + interval * g[qIndex]) mod Modulus
      start = right + 1
    answers[outIndex] = total
  for i in 0 ..< count:
    var bits = uint64(answers[i])
    for byte in 0 ..< 8:
      output[8 * i + byte] = uint8(bits and 255)
      bits = bits shr 8
  int64(needed)
