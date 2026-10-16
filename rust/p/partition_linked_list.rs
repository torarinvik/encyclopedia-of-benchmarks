const MOD: i64 = 1_000_000_007;
const BASE: i64 = 2_000_000_003;
#[no_mangle]
pub unsafe extern "C" fn partition_linked_list(v: *const i64, n: usize) -> i64 {
    if v.is_null() || n < 2 || n > 66 { return -1; }
    let a = std::slice::from_raw_parts(v, n);
    if !(0..=64).contains(&a[0]) || n != a[0] as usize + 2 || a[1] < i32::MIN as i64 || a[1] > i32::MAX as i64 { return -1; }
    let mut less = [0i64;64]; let mut ge = [0i64;64]; let mut l=0usize; let mut g=0usize;
    for &x in &a[2..] { if x < i32::MIN as i64 || x > i32::MAX as i64 { return -1; } if x < a[1] { less[l]=x;l+=1; } else { ge[g]=x;g+=1; } }
    let mut h=0i64; for &x in less[..l].iter().chain(ge[..g].iter()) { h=(h*BASE+x-i32::MIN as i64)%MOD; } h
}
