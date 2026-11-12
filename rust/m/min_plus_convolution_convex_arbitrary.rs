const MAX_INPUT: usize = 67;
const MAX_OUTPUT: usize = 504;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn min_plus_convolution_convex_arbitrary(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    let n0 = words[0]; let m0 = words[1];
    if !(1..=32).contains(&n0) || !(1..=32).contains(&m0) { return -1; }
    let n = n0 as usize; let m = m0 as usize;
    if length != 2 + n + m { return -1; }
    let a = &words[2..2+n]; let b = &words[2+n..];
    if words[2..].iter().any(|&x| !(0..=1_000_000_000).contains(&x)) { return -1; }
    for i in 0..n.saturating_sub(2) { if a[i+1]-a[i] > a[i+2]-a[i+1] { return -1; } }
    let count = n + m - 1; let bytes = 8 * count;
    if bytes > MAX_OUTPUT { return -1; }
    if output.is_null() || capacity < bytes { return -2; }
    let mut result = [0i64; 63];
    let mut stack = [(0usize,0usize,0usize,0usize);128];
    let mut top = 1usize; stack[0] = (0,count-1,0,m-1);
    while top > 0 {
        top -= 1;
        let (left,right,opt_left,opt_right) = stack[top];
        if left > right { continue; }
        let mid = left + (right-left)/2;
        let low = opt_left.max(mid.saturating_sub(n-1));
        let high = opt_right.min(m-1).min(mid);
        let mut best = i64::MAX; let mut best_j = low;
        for j in low..=high { let value = a[mid-j] + b[j]; if value < best { best=value; best_j=j; } }
        result[mid] = best;
        if mid < right { stack[top]=(mid+1,right,best_j,opt_right); top+=1; }
        if left < mid { stack[top]=(left,mid-1,opt_left,best_j); top+=1; }
    }
    for i in 0..count { store_i64_le(output,8*i,result[i]); }
    bytes as i64
}
