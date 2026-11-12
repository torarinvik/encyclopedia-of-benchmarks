const MaxN = 16
const MaxInputValues = 1 + MaxN * MaxN
const States = 1 shl MaxN
const Modulus = 998244353'i64

proc storeI64Le(output: ptr UncheckedArray[uint8], value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[byte] = uint8((bits shr (8 * byte)) and 255)

proc hafnian_of_matrix*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "hafnian_of_matrix".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputValues): return -1
  let nValue = input[0]
  if nValue < 2 or nValue > int64(MaxN) or nValue mod 2 != 0: return -1
  let n = int(nValue)
  if length != csize_t(1 + n * n): return -1

  var matrix: array[MaxN * MaxN, int64]
  for row in 0 ..< n:
    for column in 0 ..< n:
      let value = input[1 + row * n + column]
      if value < 0 or value >= Modulus or (row == column and value != 0): return -1
      matrix[row * MaxN + column] = value
  for row in 0 ..< n:
    for column in 0 ..< row:
      if matrix[row * MaxN + column] != matrix[column * MaxN + row]: return -1

  var dp: array[States, int64]
  dp[0] = 1
  var full = 1
  for _ in 0 ..< n: full *= 2
  dec full
  for mask in 1 .. full:
    var bits = mask
    var parity = 0
    while bits > 0:
      parity = (parity + bits mod 2) mod 2
      bits = bits div 2
    if parity != 0: continue
    var first = 0
    while (mask div (1 shl first)) mod 2 == 0: inc first
    let withoutFirst = mask - (1 shl first)
    for second in first + 1 ..< n:
      if (withoutFirst div (1 shl second)) mod 2 == 0: continue
      let rest = withoutFirst - (1 shl second)
      dp[mask] = (dp[mask] + matrix[first * MaxN + second] * dp[rest]) mod Modulus

  if output.isNil or capacity < 8: return -2
  storeI64Le(output, dp[full])
  8
