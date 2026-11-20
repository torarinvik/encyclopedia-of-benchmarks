const GENERATIONS: usize = 4;
const BUCKETS: usize = 8;
const MAX_KEYS: usize = 32;
const MAX_OPS: usize = 64;
const MAX_WORDS: usize = 1 + 3 * MAX_OPS + 1;
const MISS: i64 = -2_147_483_648;

fn find_in_table(heads: &[[i16; BUCKETS]; GENERATIONS],
                 keys: &[[i16; MAX_KEYS]; GENERATIONS],
                 links: &[[i16; MAX_KEYS]; GENERATIONS], table: usize, key: i16) -> Option<usize> {
    let mut node = heads[table][key as usize % BUCKETS];
    while node >= 0 {
        let index = node as usize;
        if keys[table][index] == key { return Some(index); }
        node = links[table][index];
    }
    None
}

fn find_key(heads: &[[i16; BUCKETS]; GENERATIONS],
            keys: &[[i16; MAX_KEYS]; GENERATIONS],
            links: &[[i16; MAX_KEYS]; GENERATIONS], newest: usize, key: i16)
            -> Option<(usize, usize)> {
    for age in 0..GENERATIONS {
        let table = (newest + age) % GENERATIONS;
        if let Some(node) = find_in_table(heads, keys, links, table, key) {
            return Some((table, node));
        }
    }
    None
}

fn put(heads: &mut [[i16; BUCKETS]; GENERATIONS],
       keys: &mut [[i16; MAX_KEYS]; GENERATIONS],
       values: &mut [[i16; MAX_KEYS]; GENERATIONS],
       links: &mut [[i16; MAX_KEYS]; GENERATIONS],
       used: &mut [usize; GENERATIONS], newest: usize, key: i16, value: i16) {
    if let Some(node) = find_in_table(heads, keys, links, newest, key) {
        values[newest][node] = value;
        return;
    }
    let Some(node) = keys[newest].iter().position(|entry| *entry < 0) else { return; };
    used[newest] += 1;
    let bucket = key as usize % BUCKETS;
    keys[newest][node] = key;
    values[newest][node] = value;
    links[newest][node] = heads[newest][bucket];
    heads[newest][bucket] = node as i16;
}

fn remove(heads: &mut [[i16; BUCKETS]; GENERATIONS],
          keys: &mut [[i16; MAX_KEYS]; GENERATIONS],
          values: &mut [[i16; MAX_KEYS]; GENERATIONS],
          links: &mut [[i16; MAX_KEYS]; GENERATIONS],
          used: &mut [usize; GENERATIONS], table: usize, key: i16, target: usize) {
    let bucket = key as usize % BUCKETS;
    let mut previous: Option<usize> = None;
    let mut node = heads[table][bucket];
    while node >= 0 && node as usize != target {
        previous = Some(node as usize);
        node = links[table][node as usize];
    }
    if node < 0 { return; }
    if let Some(prior) = previous { links[table][prior] = links[table][target]; }
    else { heads[table][bucket] = links[table][target]; }
    keys[table][target] = -1;
    values[table][target] = 0;
    links[table][target] = -1;
    used[table] -= 1;
}

fn write_i64_le(output: *mut u8, index: usize, value: i64) {
    for byte in 0..8 {
        unsafe { output.add(index * 8 + byte).write((value as u64 >> (8 * byte)) as u8); }
    }
}

#[no_mangle]
pub unsafe extern "C" fn hashbelt_aging_hash_table(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_WORDS { return -1; }
    let count_value = unsafe { *input };
    if count_value < 0 || count_value > MAX_OPS as i64 { return -1; }
    let count = count_value as usize;
    if length != 1 + 3 * count { return -1; }
    for op in 0..count {
        let opcode = unsafe { *input.add(1 + 3 * op) };
        let key = unsafe { *input.add(2 + 3 * op) };
        let argument = unsafe { *input.add(3 + 3 * op) };
        let valid = match opcode {
            0 => (0..MAX_KEYS as i64).contains(&key) && (-1000..=1000).contains(&argument),
            1 => (0..MAX_KEYS as i64).contains(&key) && argument == 0,
            2 => key == 0 && argument == 0,
            _ => false,
        };
        if !valid { return -1; }
    }
    let required = count * 8;
    if output.is_null() || capacity < required { return -2; }

    let mut heads = [[-1i16; BUCKETS]; GENERATIONS];
    let mut keys = [[-1i16; MAX_KEYS]; GENERATIONS];
    let mut values = [[0i16; MAX_KEYS]; GENERATIONS];
    let mut links = [[-1i16; MAX_KEYS]; GENERATIONS];
    let mut used = [0usize; GENERATIONS];
    let mut trace = [0i64; MAX_OPS];
    let mut newest = 0usize;
    for op in 0..count {
        let opcode = unsafe { *input.add(1 + 3 * op) } as usize;
        let key = unsafe { *input.add(2 + 3 * op) } as i16;
        let argument = unsafe { *input.add(3 + 3 * op) } as i16;
        match opcode {
            0 => {
                let old = find_key(&heads, &keys, &links, newest, key);
                trace[op] = if old.is_none() { 1 } else { 0 };
                if let Some((table, node)) = old {
                    if table != newest {
                        remove(&mut heads, &mut keys, &mut values, &mut links, &mut used, table, key, node);
                    }
                }
                put(&mut heads, &mut keys, &mut values, &mut links, &mut used, newest, key, argument);
            }
            1 => {
                if let Some((table, node)) = find_key(&heads, &keys, &links, newest, key) {
                    let value = values[table][node];
                    trace[op] = value as i64;
                    if table != newest {
                        remove(&mut heads, &mut keys, &mut values, &mut links, &mut used, table, key, node);
                        put(&mut heads, &mut keys, &mut values, &mut links, &mut used, newest, key, value);
                    }
                } else { trace[op] = MISS; }
            }
            _ => {
                let oldest = (newest + GENERATIONS - 1) % GENERATIONS;
                trace[op] = used[oldest] as i64;
                heads[oldest] = [-1; BUCKETS];
                keys[oldest] = [-1; MAX_KEYS];
                used[oldest] = 0;
                newest = oldest;
            }
        }
    }
    for op in 0..count { write_i64_le(output, op, trace[op]); }
    required as i64
}
