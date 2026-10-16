const max_row = 30
const modulus = i64(1000000007)
@[export: 'pascal_triangle_ii']
pub fn pascal_triangle_ii(row i64) i64 {
 if row < 0 || row > max_row { return i64(-9223372036854775807 - 1) }
 mut triangle := [31 * 31]i64{}
 triangle[0] = 1
 for i in 1 .. int(row) + 1 {
  triangle[i * 31] = 1; triangle[i * 31 + i] = 1
  for j in 1 .. i { triangle[i * 31 + j] = triangle[(i - 1) * 31 + j - 1] + triangle[(i - 1) * 31 + j] }
 }
 mut hash := i64(0)
 for j in 0 .. int(row) + 1 { hash = (hash * 31 + triangle[int(row) * 31 + j]) % modulus }
 return hash
}
