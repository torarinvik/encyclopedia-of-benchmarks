const Limbs = 8

proc divideWords(dividend, divisor: array[Limbs, uint32],
                quotient: var array[Limbs, uint32], remainder: var array[Limbs, uint32]) =
  var rem: array[Limbs + 1, uint32]
  for offset in 0 ..< Limbs * 32:
    let bit = Limbs * 32 - 1 - offset
    var carry = (dividend[bit div 32] shr (bit mod 32)) and 1'u32
    for i in 0 ..< Limbs:
      let next = rem[i] shr 31
      rem[i] = (rem[i] shl 1) or carry
      carry = next
    rem[Limbs] = carry
    var comparison = if rem[Limbs] == 0: 0 else: 1
    if comparison == 0:
      var i = Limbs
      while i > 0:
        dec i
        if rem[i] > divisor[i]: comparison = 1; break
        if rem[i] < divisor[i]: comparison = -1; break
    if comparison >= 0:
      var borrow = 0'u64
      for i in 0 ..< Limbs:
        let sub = uint64(divisor[i]) + borrow
        let old = uint64(rem[i])
        if old >= sub: rem[i] = uint32(old - sub); borrow = 0
        else: rem[i] = uint32(old + 0x1_0000_0000'u64 - sub); borrow = 1
      rem[Limbs] = uint32(uint64(rem[Limbs]) - borrow)
      quotient[bit div 32] = quotient[bit div 32] or (1'u32 shl (bit mod 32))
  for i in 0 ..< Limbs: remainder[i] = rem[i]

proc uint256_t*(input: ptr UncheckedArray[int64], length: csize_t,
                output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "uint256_t".} =
  if input.isNil or length < 1 or length > 18 or length != 1 + 2 * Limbs: return -1
  if input[0] != 0 and input[0] != 1: return -1
  var dividend: array[Limbs, uint32]
  var divisor: array[Limbs, uint32]
  var divisorNonzero = false
  for i in 0 ..< Limbs:
    let a = input[1 + i]
    let b = input[1 + Limbs + i]
    if a < 0 or a > 4_294_967_295'i64 or b < 0 or b > 4_294_967_295'i64: return -1
    dividend[i] = uint32(a)
    divisor[i] = uint32(b)
    divisorNonzero = divisorNonzero or divisor[i] != 0
  if not divisorNonzero: return -1
  if output.isNil or capacity < 32: return -2
  var quotient: array[Limbs, uint32]
  var remainder: array[Limbs, uint32]
  divideWords(dividend, divisor, quotient, remainder)
  let answer = if input[0] == 0: quotient else: remainder
  for i in 0 ..< Limbs:
    for byte in 0 ..< 4: output[i * 4 + byte] = uint8((answer[i] shr (byte * 8)) and 0xff'u32)
  32
