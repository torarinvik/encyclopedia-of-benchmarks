const MaxN = 2_147_483_647'i64

proc nextWord(state: var uint64): uint64 =
  state = state +% 0x9E3779B97F4A7C15'u64
  var z = state
  z = (z xor (z shr 30)) *% 0xBF58476D1CE4E5B9'u64
  z = (z xor (z shr 27)) *% 0x94D049BB133111EB'u64
  z xor (z shr 31)

proc modPower(baseValue, exponentValue, modulus: int64): int64 =
  var base = baseValue
  var exponent = exponentValue
  var result = 1'i64
  while exponent > 0:
    if (exponent and 1) != 0: result = (result * base) mod modulus
    base = (base * base) mod modulus
    exponent = exponent shr 1
  result

proc passesWitness(n, a, d, powersOfTwo: int64): bool =
  var x = modPower(a, d, n)
  if x == 1 or x == n - 1: return true
  var round = 1'i64
  while round < powersOfTwo:
    x = (x * x) mod n
    if x == n - 1: return true
    inc round
  false

proc miller_rabin_primality_checker*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "miller_rabin_primality_checker".} =
  if values == nil or length < 3 or length > 4: return -1
  let n = values[0]
  let rounds = values[1]
  let seed = values[2]
  if length != 3 or n < 5 or n > MaxN or (n and 1) == 0 or rounds < 1 or rounds > 64 or seed < 0 or seed > MaxN: return -1
  var state = uint64(seed)
  let span = uint64(n - 4)
  let threshold = (0'u64 -% span) mod span
  var word: uint64
  while true:
    word = nextWord(state)
    if word >= threshold: break
  let a = 2'i64 + int64(word mod span)
  var d = n - 1
  var powersOfTwo = 0'i64
  while (d and 1) == 0:
    d = d shr 1
    inc powersOfTwo
  for _ in 0'i64 ..< rounds:
    if not passesWitness(n, a, d, powersOfTwo): return 0
  1
