/// Count unordered partitions of a positive integer using the pinned 2D DP.
#[no_mangle]
pub extern "C" fn integer_partition(m: i64) -> i64 {
    if !(1..=300).contains(&m) {
        return i64::MIN;
    }
    let stride = 300usize;
    let m = m as usize;
    let mut memo = vec![0i64; 301 * stride];
    for i in 0..=m {
        memo[i * stride] = 1;
    }
    for n in 0..=m {
        for k in 1..m {
            let index = n * stride + k;
            memo[index] += memo[index - 1];
            if n > k {
                memo[index] += memo[(n - k - 1) * stride + k];
            }
        }
    }
    memo[m * stride + m - 1]
}
