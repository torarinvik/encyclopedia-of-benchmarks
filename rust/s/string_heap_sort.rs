const MAX_KEYS: usize = 64;
const WIDTH: usize = 4;
fn sift_down(a: &mut [u32; MAX_KEYS], mut root: usize, end: usize) {
    while root < end / 2 {
        let mut child = 2 * root + 1;
        if child + 1 < end && a[child] < a[child + 1] { child += 1; }
        if a[root] >= a[child] { break; }
        a.swap(root, child); root = child;
    }
}
#[no_mangle]
pub unsafe extern "C" fn string_heap_sort(values: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if values.is_null() || length < 1 || length > 1 + MAX_KEYS * WIDTH { return -1; }
    let v = std::slice::from_raw_parts(values, length);
    if v[0] < 0 || v[0] > MAX_KEYS as i64 { return -1; }
    let n = v[0] as usize;
    if length != 1 + WIDTH * n { return -1; }
    let mut a = [0u32; MAX_KEYS];
    for i in 0..n { let mut key = 0u32; for b in 0..WIDTH {
        let x = v[1 + WIDTH*i + b]; if !(0..=127).contains(&x) { return -1; }
        key = (key << 8) | x as u32;
    } a[i] = key; }
    for start in (0..n/2).rev() { sift_down(&mut a, start, n); }
    for end in (1..n).rev() { a.swap(0,end); sift_down(&mut a,0,end); }
    let bytes = n * WIDTH;
    if output.is_null() || capacity < bytes { return -2; }
    for i in 0..n { for b in 0..WIDTH { *output.add(i*WIDTH+b) = (a[i] >> (24-8*b)) as u8; } }
    bytes as i64
}
