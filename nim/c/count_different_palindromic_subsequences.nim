const MaxLength = 20
const Modulus = 1_000_000_007'i64

proc normalize(value: int64): int64 =
  result = value mod Modulus
  if result < 0: result += Modulus

proc count_different_palindromic_subsequences*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "count_different_palindromic_subsequences".} =
  if input == nil or length < 1 or length > 22: return -1
  let nValue = input[0]
  if nValue < 0 or nValue > MaxLength or int64(length) != nValue + 1: return -1
  let n = int(nValue)
  var symbols: array[MaxLength, int]
  for i in 0 ..< n:
    if input[i + 1] < 0 or input[i + 1] > 3: return -1
    symbols[i] = int(input[i + 1])
  if n == 0: return 0

  var nextEqual, previousEqual: array[MaxLength, int]
  var nextAt: array[4, int]
  var previousAt: array[4, int]
  for symbol in 0 ..< 4:
    nextAt[symbol] = n
    previousAt[symbol] = -1
  for i in countdown(n - 1, 0):
    nextEqual[i] = nextAt[symbols[i]]
    nextAt[symbols[i]] = i
  for i in 0 ..< n:
    previousEqual[i] = previousAt[symbols[i]]
    previousAt[symbols[i]] = i

  var dp: array[MaxLength, array[MaxLength, int64]]
  for i in 0 ..< n: dp[i][i] = 1
  if n >= 2:
    for width in 2 .. n:
      for left in 0 .. n - width:
        let right = left + width - 1
        let inner = if width > 2: dp[left + 1][right - 1] else: 0'i64
        var value: int64
        if symbols[left] != symbols[right]:
          value = dp[left + 1][right] + dp[left][right - 1] - inner
        else:
          let first = nextEqual[left]
          let last = previousEqual[right]
          if first >= right or last <= left or first > last:
            value = 2 * inner + 2
          elif first == last:
            value = 2 * inner + 1
          else:
            let duplicates = if first + 1 <= last - 1: dp[first + 1][last - 1] else: 0'i64
            value = 2 * inner - duplicates
        dp[left][right] = normalize(value)
  dp[0][n - 1]
