const MAX_N: usize = 128;

#[no_mangle]
pub unsafe extern "C" fn nussinov(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 1 {
        return -1;
    }
    let n_value = *values;
    if !(1..=MAX_N as i64).contains(&n_value) {
        return -1;
    }
    let n = n_value as usize;
    let mut bases = [0i64; MAX_N];
    let mut table = [[0i64; MAX_N]; MAX_N];
    for i in 0..n {
        bases[i] = ((i + 1) % 4) as i64;
    }

    for i in (0..n).rev() {
        for j in (i + 1)..n {
            let mut score = table[i][j - 1];
            if i + 1 < n {
                score = score.max(table[i + 1][j]);
                let mut inside = table[i + 1][j - 1];
                if i < j - 1 && bases[i] + bases[j] == 3 {
                    inside += 1;
                }
                score = score.max(inside);
            }
            for k in (i + 1)..j {
                score = score.max(table[i][k] + table[k + 1][j]);
            }
            table[i][j] = score;
        }
    }

    let mut checksum = 0i64;
    for i in 0..n {
        for j in i..n {
            checksum += table[i][j];
        }
    }
    checksum
}
