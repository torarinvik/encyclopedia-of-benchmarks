const MAX_TOTAL: i64 = 200;
const MAX_PARTS: usize = 200;
const MEMO_SIZE: usize = (MAX_PARTS + 1) * MAX_PARTS;

#[no_mangle]
pub extern "C" fn problem76(total: i64) -> i64 {
    if total < 1 || total > MAX_TOTAL { return -1; }
    let bound = total as usize;
    let mut memo = [0i64; MEMO_SIZE];
    for n in 0..=bound { memo[n * MAX_PARTS] = 1; }
    for n in 0..=bound {
        for k in 1..bound {
            let index = n * MAX_PARTS + k;
            memo[index] += memo[index - 1];
            if n > k { memo[index] += memo[(n - k - 1) * MAX_PARTS + k]; }
        }
    }
    memo[bound * MAX_PARTS + bound - 1] - 1
}
