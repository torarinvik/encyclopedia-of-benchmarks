const
  MaxOrder = 8
  Modulus = 998244353'i64
  MaxInput = 2 + 2 * MaxOrder

type
  Polynomial = array[MaxOrder + 1, int64]
  Product = array[2 * MaxOrder + 1, int64]

proc convolve(left: Polynomial, leftLen: int, right: Polynomial, rightLen: int): Product =
  for i in 0 ..< leftLen + rightLen - 1:
    result[i] = 0
  for i in 0 ..< leftLen:
    for j in 0 ..< rightLen:
      let at = i + j
      result[at] = (result[at] + left[i] * right[j]) mod Modulus

proc bostan_mori_recurrence_term*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "bostan_mori_recurrence_term".} =
  if input.isNil or length < csize_t(2): return -1
  let orderWord = input[0]
  let indexWord = input[1]
  if orderWord < 1 or orderWord > int64(MaxOrder)
      or indexWord < 0 or indexWord > 1_000_000_000_000_000_000'i64: return -1
  let order = int(orderWord)
  if length != csize_t(2 + 2 * order): return -1

  var numerator, initial, denominator: Polynomial
  denominator[0] = 1
  for i in 0 ..< order:
    let coefficient = input[2 + i]
    initial[i] = input[2 + order + i]
    if coefficient < 0 or coefficient >= Modulus or initial[i] < 0 or initial[i] >= Modulus:
      return -1
    denominator[i + 1] = (Modulus - coefficient) mod Modulus
  let firstProduct = convolve(initial, order, denominator, order + 1)
  for i in 0 ..< order: numerator[i] = firstProduct[i]

  var index = uint64(indexWord)
  while index > 0:
    var denominatorNegative: Polynomial
    for i in 0 .. order:
      if (i and 1) == 0 or denominator[i] == 0:
        denominatorNegative[i] = denominator[i]
      else:
        denominatorNegative[i] = Modulus - denominator[i]
    let numeratorProduct = convolve(numerator, order, denominatorNegative, order + 1)
    let denominatorProduct = convolve(denominator, order + 1, denominatorNegative, order + 1)
    let parity = int(index and 1)
    for i in 0 ..< order: numerator[i] = numeratorProduct[2 * i + parity]
    for i in 0 .. order: denominator[i] = denominatorProduct[2 * i]
    index = index shr 1
  numerator[0]
