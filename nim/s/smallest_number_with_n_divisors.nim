const MaxInput = 3
const MaxStack = 128
const MaxDivisorCount = 63'i64
const MaxLimit = 1_000_000'i64
const Primes: array[5, int64] = [2'i64, 3, 5, 7, 11]

proc smallest_number_with_n_divisors*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "smallest_number_with_n_divisors".} =
  if input == nil or length < 2 or length > csize_t(MaxInput) or length != 2: return -1
  let divisorCount = input[0]
  let limit = input[1]
  if divisorCount < 1 or divisorCount > MaxDivisorCount or limit < 1 or limit > MaxLimit: return -1

  var remainingStack: array[MaxStack, int64]
  var maxFactorStack: array[MaxStack, int64]
  var primeIndexStack: array[MaxStack, int64]
  var productStack: array[MaxStack, int64]
  var top = 1
  remainingStack[0] = divisorCount
  maxFactorStack[0] = divisorCount
  productStack[0] = 1
  var best = limit + 1

  while top > 0:
    dec top
    let remaining = remainingStack[top]
    let maxFactor = maxFactorStack[top]
    let primeIndex = primeIndexStack[top]
    let product = productStack[top]
    if remaining == 1:
      if product < best: best = product
      continue
    if primeIndex >= int64(Primes.len): continue
    let prime = Primes[int(primeIndex)]
    let factorLimit = if maxFactor < remaining: maxFactor else: remaining
    var factor = 2'i64
    while factor <= factorLimit:
      if remaining mod factor == 0:
        var candidate = product
        var valid = true
        var step = 1'i64
        while step < factor:
          if candidate > limit div prime:
            valid = false
            break
          candidate *= prime
          inc step
        if valid and candidate < best:
          if top >= MaxStack: return -1
          remainingStack[top] = remaining div factor
          maxFactorStack[top] = factor
          primeIndexStack[top] = primeIndex + 1
          productStack[top] = candidate
          inc top
      inc factor
  if best <= limit: best else: 0
