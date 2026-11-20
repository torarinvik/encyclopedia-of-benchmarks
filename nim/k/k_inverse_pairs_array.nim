const MaxN = 128
const MaxK = 512
const Modulus = 1_000_000_007'i64

proc k_inverse_pairs_array*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "k_inverse_pairs_array".} =
  if input == nil or length < 1 or length > 3 or length != 2: return -1
  let nValue = input[0]
  let kValue = input[1]
  if nValue < 0 or nValue > MaxN or kValue < 0 or kValue > MaxK: return -1
  let n = int(nValue)
  let k = int(kValue)
  let maxInversions = if n > 0: n * (n - 1) div 2 else: 0
  if k > maxInversions: return 0

  var previous: array[MaxK + 1, int64]
  var current: array[MaxK + 1, int64]
  previous[0] = 1
  for size in 1 .. n:
    var window = 0'i64
    for inversions in 0 .. k:
      window += previous[inversions]
      if inversions >= size: window -= previous[inversions - size]
      window = window mod Modulus
      if window < 0: window += Modulus
      current[inversions] = window
    previous = current
    current = default(array[MaxK + 1, int64])
  previous[k]
