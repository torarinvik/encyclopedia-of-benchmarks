const MaxRow = 30
const Modulus = 1_000_000_007'i64
proc pascal_triangle_ii*(row: int64): int64 {.cdecl, exportc: "pascal_triangle_ii".} =
  if row < 0 or row > MaxRow: return low(int64)
  var triangle: array[31 * 31, int64]
  triangle[0] = 1
  for i in 1..int(row):
    triangle[i * 31] = 1; triangle[i * 31 + i] = 1
    for j in 1..<i: triangle[i * 31 + j] = triangle[(i - 1) * 31 + j - 1] + triangle[(i - 1) * 31 + j]
  var hash = 0'i64
  for j in 0..int(row): hash = (hash * 31 + triangle[int(row) * 31 + j]) mod Modulus
  hash
