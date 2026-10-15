/// Forward-tabulated minimum steps from 1 using +1, *2, or *3.
const MAX_N: usize = 10_000;

#[no_mangle]
pub extern "C" fn minimum_steps_to_one(n: i64) -> i64 {
    if n < 1 || n as usize > MAX_N { return -1; }
    let n = n as usize;
    let mut table = [0i64; MAX_N + 1];
    table[..=n].fill(n as i64 + 1);
    table[1] = 0;
    for i in 1..n {
        let candidate = table[i] + 1;
        if table[i + 1] > candidate { table[i + 1] = candidate; }
        if i * 2 <= n && table[i * 2] > candidate { table[i * 2] = candidate; }
        if i * 3 <= n && table[i * 3] > candidate { table[i * 3] = candidate; }
    }
    table[n]
}
