//! Uncompiled exact-length directed walk counting draft.
#[no_mangle]
pub unsafe extern "C" fn fixed_length_walk_count(input: *const i64, length: usize) -> i64 {
    const MOD: i64 = 1_000_000_007;
    if input.is_null() || !(4..=261).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let (nv, mut k, source, target) = (values[0], values[1], values[2], values[3]);
    if !(1..=16).contains(&nv) || !(0..=1_000_000_000).contains(&k)
        || source < 0 || source >= nv || target < 0 || target >= nv
        || length != 4 + (nv*nv) as usize { return -1; }
    let n = nv as usize;
    let mut matrix = [[0i64; 16]; 16];
    let mut vector = [0i64; 16];
    for i in 0..n { for j in 0..n {
        let value = values[4+i*n+j];
        if !(0..=100).contains(&value) { return -1; }
        matrix[i][j] = value;
    } }
    vector[source as usize] = 1;
    while k > 0 {
        if k & 1 != 0 {
            let mut next = [0i64; 16];
            for i in 0..n { for j in 0..n {
                next[j] = (next[j] + vector[i] * matrix[i][j]) % MOD;
            } }
            vector = next;
        }
        k >>= 1;
        if k > 0 {
            let mut next = [[0i64; 16]; 16];
            for i in 0..n { for p in 0..n { for j in 0..n {
                next[i][j] = (next[i][j] + matrix[i][p] * matrix[p][j]) % MOD;
            } } }
            matrix = next;
        }
    }
    vector[target as usize]
}
