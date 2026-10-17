const MAX_N: usize = 11;
const FNV_OFFSET_BASIS: u64 = 14_695_981_039_346_656_037;
const FNV_PRIME: u64 = 1_099_511_628_211;
const I64_RESULT_MASK: u64 = 0x7fff_ffff_ffff_ffff;

fn fnv_byte(hash: &mut u64, value: u8) {
    *hash = (*hash ^ u64::from(value)).wrapping_mul(FNV_PRIME);
}

fn enumerate(n: usize, hash: &mut u64, hash_rows: bool) -> u32 {
    if n == 0 { return 1; }

    let mut vector = [0u8; MAX_N];
    let mut frequencies = [0u8; MAX_N];
    let mut next_candidate = [0u8; MAX_N];
    let mut prefix_sum = [0u8; MAX_N + 1];
    let mut depth = 0usize;
    let mut solution_count = 0u32;

    loop {
        if depth == n {
            let mut is_magic = true;
            for symbol in 0..n {
                if frequencies[symbol] != vector[symbol] {
                    is_magic = false;
                    break;
                }
            }
            if is_magic {
                solution_count += 1;
                if hash_rows {
                    for index in 0..n {
                        fnv_byte(hash, vector[index]);
                    }
                }
            }
            depth -= 1;
            frequencies[usize::from(vector[depth])] -= 1;
            continue;
        }

        let candidate = next_candidate[depth];
        if usize::from(candidate) >= n {
            next_candidate[depth] = 0;
            if depth == 0 { break; }
            depth -= 1;
            frequencies[usize::from(vector[depth])] -= 1;
            continue;
        }
        next_candidate[depth] = candidate + 1;
        let sum = usize::from(prefix_sum[depth]) + usize::from(candidate);
        if sum > n { continue; }

        vector[depth] = candidate;
        frequencies[usize::from(candidate)] += 1;
        prefix_sum[depth + 1] = sum as u8;
        depth += 1;
        next_candidate[depth] = 0;
    }
    solution_count
}

#[no_mangle]
pub unsafe extern "C" fn magic_sequence(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let n_value = *input;
    if n_value < 0 || n_value > MAX_N as i64 { return -1; }
    let n = n_value as usize;

    let mut hash = FNV_OFFSET_BASIS;
    fnv_byte(&mut hash, n as u8);
    let solution_count = enumerate(n, &mut hash, false);
    for byte in solution_count.to_le_bytes() {
        fnv_byte(&mut hash, byte);
    }
    enumerate(n, &mut hash, true);
    (hash & I64_RESULT_MASK) as i64
}
