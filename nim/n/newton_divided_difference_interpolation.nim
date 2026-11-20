const
  Modulus = 998244353'i64
  MaxNodes = 12
  MaxLength = 27

proc modPow(baseValue, exponentValue: int64): int64 =
  var base = baseValue
  var exponent = exponentValue
  var result = 1'i64
  while exponent > 0:
    if (exponent and 1) != 0: result = (result * base) mod Modulus
    base = (base * base) mod Modulus
    exponent = exponent shr 1
  result

proc newton_divided_difference_interpolation*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "newton_divided_difference_interpolation".} =
  if input == nil or length < 4 or length > csize_t(MaxLength): return -1
  if input[0] < 1 or input[0] > int64(MaxNodes): return -1
  let count = int(input[0])
  if int(length) != 2 + 2 * count: return -1
  var nodes: array[MaxNodes, int64]
  var differences: array[MaxNodes, int64]
  for i in 0 ..< count:
    nodes[i] = input[1 + i]
    differences[i] = input[1 + count + i]
    if nodes[i] < 0 or nodes[i] >= Modulus or differences[i] < 0 or differences[i] >= Modulus: return -1
    for j in 0 ..< i:
      if nodes[i] == nodes[j]: return -1
  let query = input[int(length) - 1]
  if query < 0 or query >= Modulus: return -1
  for order in 1 ..< count:
    for offset in 0 ..< count - order:
      let i = count - 1 - offset
      var numerator = differences[i] - differences[i - 1]
      if numerator < 0: numerator += Modulus
      var denominator = nodes[i] - nodes[i - order]
      if denominator < 0: denominator += Modulus
      differences[i] = (numerator * modPow(denominator, Modulus - 2)) mod Modulus
  var result = differences[count - 1]
  if count > 1:
    for offset in 0 ..< count - 1:
      let i = count - 2 - offset
      var factor = query - nodes[i]
      if factor < 0: factor += Modulus
      result = (result * factor + differences[i]) mod Modulus
  result
