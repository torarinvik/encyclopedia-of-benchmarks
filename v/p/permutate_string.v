const max_len = 7
fn next_perm(mut a [max_len]u8, n int) bool {
 mut i := n - 1
 for i > 0 && a[i - 1] >= a[i] { i-- }
 if i == 0 { return false }
 mut j := n - 1
 for a[j] <= a[i - 1] { j-- }
 a[i - 1], a[j] = a[j], a[i - 1]
 mut l := i; mut r := n - 1
 for l < r { a[l], a[r] = a[r], a[l]; l++; r-- }
 return true
}
fn mix(h u32, b u8) u32 { return u32((u64(h ^ u32(b)) * u64(16777619)) & u64(0xffffffff)) }
@[export: 'permutate_string']
pub fn permutate_string(v &i64, n usize) i64 {
 unsafe {
  if v == nil || n < 2 || n > 8 || v[0] < 1 || v[0] > 7 || n != usize(v[0] + 1) { return -1 }
  len := int(v[0]); mut a := [max_len]u8{}
  for i in 0 .. len { if v[i + 1] < 33 || v[i + 1] > 126 { return -1 }; a[i] = u8(v[i + 1]); for j in 0 .. i { if a[j] == a[i] { return -1 } } }
  for i in 1 .. len { mut j := i; for j > 0 && a[j - 1] > a[j] { a[j - 1], a[j] = a[j], a[j - 1]; j-- } }
  mut h := u32(2166136261)
  for { for i in 0 .. len { h = mix(h, a[i]) }; h = mix(h, 0); if !next_perm(mut a, len) { break } }
  return i64(h)
 }
}
