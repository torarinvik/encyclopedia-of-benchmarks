## Count primes through limit with the linear (Euler) sieve.
proc linear_sieve*(limit: int64): int64 {.cdecl, exportc: "linear_sieve".} =
  if limit < 0 or limit > 4096: return -1
  if limit < 2: return 0
  var state: array[4662, int64]
  for index in 0 ..< state.len: state[index] = 0
  for value in 2 .. int(limit):
    if state[value] == 0:
      state[value] = int64(value)
      state[4097 + int(state[4661])] = int64(value)
      inc state[4661]
    var index = 0
    while int64(index) < state[4661]:
      let prime = state[4097 + index]
      if prime > state[value] or prime > limit div int64(value): break
      state[value * int(prime)] = prime
      inc index
  state[4661]
