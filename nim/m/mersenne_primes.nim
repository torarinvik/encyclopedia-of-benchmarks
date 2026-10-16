proc mersenne_primes*(n: int64): int64 {.cdecl, exportc: "mersenne_primes".} =
  if n < 2 or n > 31: return -1
  if n == 2: return 1
  let modulus = (1'i64 shl int(n)) - 1
  var residue = 4'i64
  for round in 0 ..< int(n - 2):
    residue = (residue * residue - 2) mod modulus
  if residue == 0: 1 else: 0
