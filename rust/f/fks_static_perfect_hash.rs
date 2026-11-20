/// Deterministic bounded two-level FKS static perfect hashing.
#[inline]
fn hash_index(a: usize, b: usize, modulus: usize, key: i64) -> usize {
    (((a * key as usize + b) % 257) % modulus)
}

#[no_mangle]
pub extern "C" fn fks_static_perfect_hash(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=19).contains(&length) {
        return -1;
    }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if !(0..=8).contains(&input[0]) || !(0..=8).contains(&input[1]) {
        return -1;
    }
    let n = input[0] as usize;
    let q = input[1] as usize;
    if length != 2 + n + q || input[2..].iter().any(|&x| !(0..=255).contains(&x)) {
        return -1;
    }
    let keys = &input[2..2 + n];
    for i in 0..n {
        for j in i + 1..n {
            if keys[i] == keys[j] { return -1; }
        }
    }

    let mut bucket_of = [0usize; 8];
    let mut bucket_sizes = [0usize; 8];
    let mut first_a = 0usize;
    let mut first_b = 0usize;
    let mut first_found = n == 0;
    for a in 1..=256 {
        if first_found { break; }
        for b in 0..=256 {
            if first_found { break; }
            let mut counts = [0usize; 8];
            for &key in keys { counts[hash_index(a, b, n, key)] += 1; }
            let square_sum: usize = counts[..n].iter().map(|&count| count * count).sum();
            if square_sum <= 4 * n {
                first_a = a;
                first_b = b;
                first_found = true;
            }
        }
    }
    if !first_found { return -1; }
    for i in 0..n {
        bucket_of[i] = hash_index(first_a, first_b, n, keys[i]);
        bucket_sizes[bucket_of[i]] += 1;
    }

    let mut slot_keys = [[0i64; 64]; 8];
    let mut occupied = [[false; 64]; 8];
    let mut local_a = [0usize; 8];
    let mut local_b = [0usize; 8];
    for bucket in 0..n {
        let count = bucket_sizes[bucket];
        if count == 0 { continue; }
        let capacity = count * count;
        let mut local_found = false;
        for a in 1..=256 {
            if local_found { break; }
            for b in 0..=256 {
                if local_found { break; }
                let mut used = [false; 64];
                let mut collision = false;
                for i in 0..n {
                    if bucket_of[i] == bucket {
                        let position = hash_index(a, b, capacity, keys[i]);
                        if used[position] { collision = true; break; }
                        used[position] = true;
                    }
                }
                if !collision {
                    local_a[bucket] = a;
                    local_b[bucket] = b;
                    for i in 0..n {
                        if bucket_of[i] == bucket {
                            let position = hash_index(a, b, capacity, keys[i]);
                            slot_keys[bucket][position] = keys[i];
                            occupied[bucket][position] = true;
                        }
                    }
                    local_found = true;
                }
            }
        }
        if !local_found { return -1; }
    }

    let mut result = 0i64;
    for i in 0..q {
        let query = input[2 + n + i];
        let mut present = false;
        if n > 0 {
            let bucket = hash_index(first_a, first_b, n, query);
            let count = bucket_sizes[bucket];
            if count > 0 {
                let position = hash_index(local_a[bucket], local_b[bucket], count * count, query);
                present = occupied[bucket][position] && slot_keys[bucket][position] == query;
            }
        }
        if present { result |= 1i64 << i; }
    }
    result
}
