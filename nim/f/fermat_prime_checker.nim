proc dotnetSample(seed: var array[56, int32], next: var int, nextP: var int): int32 =
  inc next
  if next >= 56: next = 1
  inc nextP
  if nextP >= 56: nextP = 1
  var value = seed[next] - seed[nextP]
  if value == 2_147_483_647'i32: dec value
  if value < 0: value += 2_147_483_647'i32
  seed[next] = value
  value

proc modPow(baseInput, exponentInput, modulus: int64): int64 =
  var base = baseInput
  var exponent = exponentInput
  var result = 1'i64
  while exponent > 0:
    if (exponent and 1) != 0: result = result * base mod modulus
    base = base * base mod modulus
    exponent = exponent shr 1
  result

proc fermat_prime_checker*(number, timesToCheck: int64): int64
    {.cdecl, exportc: "fermat_prime_checker".} =
  if number < 2 or number > 1_000_000 or timesToCheck < 2 or timesToCheck > 64: return -1
  var seed: array[56, int32]
  var mj = 161_803_398'i32
  var mk = 1'i32
  seed[55] = mj
  for i in 1 ..< 55:
    let index = (21 * i) mod 55
    seed[index] = mk
    mk = mj - mk
    if mk < 0: mk += 2_147_483_647'i32
    mj = seed[index]
  for _ in 0 ..< 4:
    for i in 1 ..< 56:
      seed[i] -= seed[1 + (i + 30) mod 55]
      if seed[i] < 0: seed[i] += 2_147_483_647'i32
  var next = 0
  var nextP = 21
  for _ in 1'i64 ..< timesToCheck:
    let sample = dotnetSample(seed, next, nextP)
    let base = int64(float64(sample) / 2_147_483_647.0 * float64(number - 1)) + 1
    if modPow(base, number - 1, number) != 1: return 0
  1
