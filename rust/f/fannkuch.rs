// Bounded port of the Benchmark Game fannkuch counter traversal.
#[no_mangle]
pub unsafe extern "C" fn fannkuch(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 1 { return -1; }
    let n64 = unsafe { *values };
    if !(1..=8).contains(&n64) { return -1; }
    let n = n64 as usize;
    let mut perm = [0i64; 8];
    let mut perm1 = [0i64; 8];
    let mut count = [0i64; 8];
    for i in 0..n { perm1[i] = i as i64; }
    let mut r = n;
    let mut flips_max = 0i64;
    loop {
        while r != 1 { count[r - 1] = r as i64; r -= 1; }
        if perm1[0] != 0 && perm1[n - 1] != (n - 1) as i64 {
            perm[1..n].copy_from_slice(&perm1[1..n]);
            let mut k = perm1[0] as usize;
            let mut flips = 0i64;
            loop {
                let (mut i, mut j) = (1usize, k - 1);
                while i < j { perm.swap(i, j); i += 1; j -= 1; }
                flips += 1;
                j = perm[k] as usize;
                perm[k] = k as i64;
                k = j;
                if k == 0 { break; }
            }
            if flips_max < flips { flips_max = flips; }
        }
        loop {
            if r == n { return flips_max; }
            let first = perm1[0];
            for i in 0..r { perm1[i] = perm1[i + 1]; }
            perm1[r] = first;
            count[r] -= 1;
            if count[r] > 0 { break; }
            r += 1;
        }
    }
}
