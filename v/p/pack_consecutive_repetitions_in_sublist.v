module pack_consecutive_repetitions_in_sublist
fn mix(h u32, b u8) u32 { return (h ^ u32(b)) * 16777619 }
fn feed(mut h u32, x u32) u32 { for shift in [u32(0), 8, 16, 24] { h = mix(h, u8(x >> shift)) }; return h }
@[export: 'pack_consecutive_repetitions_in_sublist']
pub fn pack_consecutive_repetitions_in_sublist(v &i64, n usize) i64 {
 unsafe {
  if v == nil || n < 1 || n > 65 || v[0] < 0 || v[0] > 64 || n != usize(v[0] + 1) { return -1 }
  count := int(v[0]); for i in 0 .. count { if v[i + 1] < -2147483648 || v[i + 1] > 2147483647 { return -1 } }
  mut h := u32(2166136261); mut i := 0
  for i < count { value := i32(v[i + 1]); mut j := i + 1; for j < count && v[j + 1] == i64(value) { j++ }; h = feed(h, u32(value)); h = feed(h, u32(j - i)); i = j }
  return i64(h)
 }
}
