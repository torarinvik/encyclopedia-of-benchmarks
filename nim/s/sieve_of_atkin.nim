## Count primes through limit with the Sieve of Atkin.
proc sieve_of_atkin*(limit: int64): int64 {.cdecl, exportc: "sieve_of_atkin".} =
  if limit < 0 or limit > 4096: return -1
  if limit < 2: return 0
  let n = int(limit)
  var sieve: array[4097, bool]
  for index in 0 ..< sieve.len: sieve[index] = false
  var x = 1
  while x <= n div x:
    let x2 = x * x
    var y = 1
    while y <= n div y:
      let y2 = y * y
      let first = 4 * x2 + y2
      if first <= n and (first mod 12 == 1 or first mod 12 == 5): sieve[first] = not sieve[first]
      let second = 3 * x2 + y2
      if second <= n and second mod 12 == 7: sieve[second] = not sieve[second]
      if x > y:
        let third = 3 * x2 - y2
        if third <= n and third mod 12 == 11: sieve[third] = not sieve[third]
      inc y
    inc x
  var candidate = 5
  while candidate <= n div candidate:
    if sieve[candidate]:
      let square = candidate * candidate
      var multiple = square
      while multiple <= n:
        sieve[multiple] = false
        multiple += square
    inc candidate
  var count = 1'i64
  if n >= 3: inc count
  for value in 5 .. n:
    if sieve[value]: inc count
  count
