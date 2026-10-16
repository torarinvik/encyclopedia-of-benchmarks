import std/math

const
  MaxPairCount = 1000
  MaxBase = 1_000_000'i64
  MaxExponent = 1_200_000'i64

proc problem99*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "problem99".} =
  if input == nil or length < 1: return -1
  let pairCountValue = input[0]
  if pairCountValue < 0 or pairCountValue > MaxPairCount: return -1
  let pairCount = int(pairCountValue)
  if length != csize_t(1 + 2 * pairCount): return -1

  var largest = 0.0
  var resultLine: int64 = 0
  for index in 0..<pairCount:
    let base = input[1 + 2 * index]
    let exponent = input[2 + 2 * index]
    if base < 1 or base > MaxBase or exponent < 0 or exponent > MaxExponent: return -1
    let value = float64(exponent) * log10(float64(base))
    if value > largest:
      largest = value
      resultLine = int64(index + 1)
  resultLine
