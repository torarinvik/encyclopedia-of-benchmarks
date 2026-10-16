const MaxModulus = 1_000_000
const MaxIndex = 55_374

proc positiveMod(value, modulus: int64): int64 =
  let remainder = value mod modulus
  if remainder < 0: remainder + modulus else: remainder

proc problem78*(modulus: int64): int64 {.cdecl, exportc: "problem78".} =
  if modulus < 1 or modulus > MaxModulus: return -1
  var partitions: array[MaxIndex + 1, uint32]
  partitions[0] = 1
  for n in 1 .. MaxIndex:
    var value = 0'i64
    var j = 1'i64
    while true:
      let first = (3 * j * j - j) div 2
      if first > n.int64: break
      let sign = if j mod 2 == 0: -1'i64 else: 1'i64
      value = positiveMod(value + sign * int64(partitions[n - int(first)]), modulus)
      let second = first + j
      if second > n.int64: break
      value = positiveMod(value + sign * int64(partitions[n - int(second)]), modulus)
      inc j
    if value == 0: return n.int64
    partitions[n] = uint32(value)
  -1
