## Count the primes through limit using the Sieve of Eratosthenes.
proc sieve_of_eratosthenes*(limit: int64): int64 {.cdecl, exportc: "sieve_of_eratosthenes".} =
  if limit < 0 or limit > 4096: return -1
  if limit < 2: return 0
  var prime: array[4097, bool]
  for value in 0 ..< prime.len: prime[value] = false
  for value in 2 .. int(limit): prime[value] = true
  var factor = 2
  while int64(factor) <= limit div int64(factor):
    if prime[factor]:
      var multiple = factor * factor
      while int64(multiple) <= limit:
        prime[multiple] = false
        multiple += factor
    inc factor
  var count = 0'i64
  for value in 2 .. int(limit):
    if prime[value]: inc count
  count
