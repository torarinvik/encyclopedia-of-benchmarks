const Modulus = 998244353'i64
const MaxWords = 11
const TableColumns = 9

proc stieltjesMod(value: int64): int64 =
  let reduced = value mod Modulus
  if reduced < 0: reduced + Modulus else: reduced

proc stieltjesMul(left, right: int64): int64 = (left * right) mod Modulus

proc stieltjesPower(baseInput, exponentInput: int64): int64 =
  var base = baseInput
  var exponent = exponentInput
  var result = 1'i64
  while exponent > 0:
    if (exponent and 1) != 0: result = stieltjesMul(result, base)
    base = stieltjesMul(base, base)
    exponent = exponent shr 1
  result

proc storeI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc stieltjes_quotient_difference_transform*(input: ptr UncheckedArray[int64],
    inputLength: csize_t, output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "stieltjes_quotient_difference_transform".} =
  if input == nil or inputLength < 3 or inputLength > MaxWords: return -1
  let countValue = input[0]
  if countValue < 2 or countValue > 9 or inputLength != csize_t(countValue + 1): return -1
  let count = int(countValue)
  for i in 0 ..< count:
    let value = input[i + 1]
    if value <= 0 or value >= Modulus: return -1

  var q: array[45, int64]
  var e: array[45, int64]
  for k in 0 ..< count - 1:
    q[TableColumns + k] = stieltjesMul(input[k + 2], stieltjesPower(input[k + 1], Modulus - 2))
  for j in 1 .. 4:
    let lastE = count - 2 * j - 1
    if lastE < 0: break
    for k in 0 .. lastE:
      e[j * TableColumns + k] = stieltjesMod(
        e[(j - 1) * TableColumns + k + 1] + q[j * TableColumns + k + 1] - q[j * TableColumns + k])
    let lastQ = count - 2 * j - 2
    if lastQ >= 0:
      for k in 0 .. lastQ:
        let pivot = e[j * TableColumns + k]
        if pivot == 0: return -1
        let product = stieltjesMul(q[j * TableColumns + k + 1], e[j * TableColumns + k + 1])
        q[(j + 1) * TableColumns + k] = stieltjesMul(product, stieltjesPower(pivot, Modulus - 2))

  let required = 8 * (count + 1)
  if output == nil or outputCapacity < csize_t(required): return -2
  storeI64(output, 0, countValue)
  for index in 1 ..< count:
    let value = if (index and 1) != 0: q[((index + 1) div 2) * TableColumns] else: e[(index div 2) * TableColumns]
    storeI64(output, 8 * index, value)
  int64(required)
