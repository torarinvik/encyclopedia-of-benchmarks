import std/math

proc isPentagonal(value: int64): bool =
  if value < 1: return false
  let discriminant = 24 * value + 1
  let root = int64(sqrt(float64(discriminant)))
  root * root == discriminant and (root + 1) mod 6 == 0

proc problem44*(limit: int64): int64 {.cdecl, exportc: "problem44".} =
  if limit < 1 or limit > 5000: return -1
  for i in 1'i64..<limit:
    let first = i * (3 * i - 1) div 2
    for j in i..<limit:
      let second = j * (3 * j - 1) div 2
      let difference = second - first
      if isPentagonal(first + second) and isPentagonal(difference): return difference
  -1
