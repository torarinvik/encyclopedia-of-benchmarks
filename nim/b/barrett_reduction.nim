const
  MaxModulus = 65535'i64
  MaxValues = 12
  MaxLength = 15
  Radix = 4294967296'i64

proc barrett_reduction*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "barrett_reduction".} =
  if input == nil or length < 2 or length > csize_t(MaxLength): return -1
  if input[0] < 2 or input[0] > MaxModulus or input[1] < 0 or input[1] > int64(MaxValues): return -1
  let modulus = input[0]
  let count = int(input[1])
  if int(length) != 2+count: return -1
  let squareBound = modulus*modulus
  for i in 0 ..< count:
    if input[2+i] < 0 or input[2+i] >= squareBound: return -1

  let reciprocal = Radix div modulus
  var checksum = 0'i64
  for i in 0 ..< count:
    let value = input[2+i]
    let quotient = (value*reciprocal) div Radix
    var remainder = value-quotient*modulus
    if remainder >= modulus: remainder -= modulus
    checksum += int64(i+1)*(remainder+1)
  checksum
