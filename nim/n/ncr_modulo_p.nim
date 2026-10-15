const InvalidResult = low(int64)

proc inverse(a, m: int64): int64 =
  var oldR = a
  var r = m
  var oldS = 1'i64
  var s = 0'i64
  while r != 0:
    let quotient = oldR div r
    let nextR = oldR - quotient * r
    let nextS = oldS - quotient * s
    oldR = r
    r = nextR
    oldS = s
    s = nextS
  if oldR == 1: (oldS + m) mod m else: -1

proc ncr_modulo_p*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "ncr_modulo_p".} =
  if values == nil or length != 4: return InvalidResult
  let size = values[0]
  let p = values[1]
  let n = values[2]
  let r = values[3]
  if size < 0 or size > 64 or p < 2 or p > 1009 or n < 0 or n > size or r < 0 or r > 64:
    return InvalidResult
  var fac: array[65, int64]
  fac[0] = 1
  for i in 1'i64 .. size: fac[int(i)] = (fac[int(i - 1)] * i) mod p
  if r > n: return 0
  if r == 1: return n mod p
  if r == 0 or r == n: return 1
  let denominator = (fac[int(r)] * fac[int(n - r)]) mod p
  let denominatorInv = inverse(denominator, p)
  if denominatorInv < 0: return -1
  (fac[int(n)] * denominatorInv) mod p
