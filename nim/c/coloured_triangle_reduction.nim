## Lucas-based closed form for repeated negative adjacent-pair sums modulo 3.

proc triangleBinomialModThree(n, k: int64): int64 =
  var coefficient = 1'i64
  var remainingN = n
  var remainingK = k
  while remainingN > 0 or remainingK > 0:
    let nDigit = remainingN mod 3
    let kDigit = remainingK mod 3
    if kDigit > nDigit: return 0
    if nDigit == 2 and kDigit == 1: coefficient = (2 * coefficient) mod 3
    remainingN = remainingN div 3
    remainingK = remainingK div 3
  coefficient

proc coloured_triangle_reduction*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "coloured_triangle_reduction".} =
  if input.isNil or length < 2 or length > 258: return -1
  let n = input[0]
  if n < 1 or n > 256 or length != csize_t(n + 1): return -1
  for index in 0 ..< int(n):
    let color = input[index + 1]
    if color < 0 or color > 2: return -1

  let rounds = n - 1
  var total = 0'i64
  for index in 0 ..< int(n):
    total = (total + triangleBinomialModThree(rounds, int64(index))
             * input[index + 1]) mod 3
  if rounds mod 2 == 0: total else: (3 - total) mod 3
