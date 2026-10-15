## Return the first source-ordered Goldbach pair as two little-endian i32 values.
proc goldbachPrime(value: int64): bool =
  if value == 2: return true
  if value < 2 or value mod 2 == 0: return false
  var divisor = 3'i64
  while divisor <= value div divisor:
    if value mod divisor == 0: return false
    divisor += 2
  true

proc goldbach_conjecture*(number: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "goldbach_conjecture".} =
  if number < 4 or number > 4096 or number mod 2 != 0: return -1
  if output == nil or outputCapacity < 8: return -2
  var first = 0'i64
  while first <= number div 2:
    let second = number - first
    if goldbachPrime(first) and goldbachPrime(second):
      let pair = [uint32(first), uint32(second)]
      for j in 0..1:
        for b in 0..3:
          output[4 * j + b] = uint8((pair[j] shr (8 * b)) and 0xff'u32)
      return 8
    inc first
  -1
