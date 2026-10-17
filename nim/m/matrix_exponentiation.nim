const MaxOrder = 8
const MaxInputWords = 18
const Mod = 1_000_000_007'i64
const MaxN = 1_000_000_000_000'i64

type Matrix = object
  cell: array[MaxOrder, array[MaxOrder, int64]]

proc multiply(left, right: Matrix, order: int): Matrix =
  var result: Matrix
  for row in 0 ..< order:
    for col in 0 ..< order:
      for inner in 0 ..< order:
        result.cell[row][col] = (result.cell[row][col] + (left.cell[row][inner] * right.cell[inner][col]) mod Mod) mod Mod
  result
proc power(matrix: Matrix, exponent: int64, order: int): Matrix =
  if exponent == 1: return matrix
  if exponent mod 2 == 1: return multiply(matrix, power(matrix, exponent - 1, order), order)
  let half = power(matrix, exponent div 2, order)
  multiply(half, half, order)

proc matrix_exponentiation*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "matrix_exponentiation".} =
  if input == nil or length < 1 or length > csize_t(MaxInputWords): return -1
  let orderRaw = input[0]
  if orderRaw < 1 or orderRaw > MaxOrder or int(length) != 2 * int(orderRaw) + 2: return -1
  let order = int(orderRaw)
  for i in 0 ..< 2 * order:
    if input[1 + i] < 0 or input[1 + i] >= Mod: return -1
  let n = input[2 * order + 1]
  if n < 0 or n > MaxN: return -1
  if n == 0: return 0
  if n <= orderRaw: return input[int(n)]
  var transition: Matrix
  for i in 0 ..< (order - 1): transition.cell[i][i + 1] = 1
  for col in 0 ..< order: transition.cell[order - 1][col] = input[2 * order - col]
  transition = power(transition, n - 1, order)
  var result = 0'i64
  for i in 0 ..< order: result = (result + (transition.cell[0][i] * input[1 + i]) mod Mod) mod Mod
  result
