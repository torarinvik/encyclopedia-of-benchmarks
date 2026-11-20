const MAX_N: usize = 7;
const MAX_Q: usize = 105;
const MAX_NODES: usize = 13;

fn write_i64(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn aho_build_rooted_triplet_tree(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 318 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=MAX_N as i64).contains(&values[0]) || values[1] < 0 { return -1; }
    let n = values[0] as usize;
    let q_limit = if n < 3 { 0 } else { n * (n - 1) * (n - 2) / 2 };
    if values[1] > q_limit as i64 { return -1; }
    let q = values[1] as usize;
    if length != 2 + 3 * q { return -1; }

    let mut triples = [[0i32; 3]; MAX_Q];
    for i in 0..q {
        let (a0, b0, c0) = (values[2 + 3 * i], values[3 + 3 * i], values[4 + 3 * i]);
        if a0 < 0 || a0 >= n as i64 || b0 < 0 || b0 >= n as i64 || c0 < 0 || c0 >= n as i64
            || a0 == b0 || a0 == c0 || b0 == c0 { return -1; }
        let (mut a, mut b) = (a0 as i32, b0 as i32);
        if a > b { std::mem::swap(&mut a, &mut b); }
        if triples[..i].iter().any(|t| t[0] == a && t[1] == b && t[2] == c0 as i32) { return -1; }
        triples[i] = [a, b, c0 as i32];
    }

    let mut kind = [0i32; MAX_NODES];
    let mut node_value = [0i32; MAX_NODES];
    let mut tasks = [0u8; MAX_NODES];
    tasks[0] = ((1u16 << n) - 1) as u8;
    let mut top = 1usize;
    let mut node_count = 0usize;
    let mut compatible = true;
    while top > 0 {
        top -= 1;
        let mask = tasks[top];
        if (mask & (mask - 1)) == 0 {
            let label = (0..n).find(|&v| mask & (1 << v) != 0).unwrap();
            kind[node_count] = 1;
            node_value[node_count] = label as i32;
            node_count += 1;
            continue;
        }
        let mut edge = [[false; MAX_N]; MAX_N];
        for t in &triples[..q] {
            let needed = (1u8 << t[0]) | (1u8 << t[1]) | (1u8 << t[2]);
            if (mask & needed) == needed { edge[t[0] as usize][t[1] as usize] = true; edge[t[1] as usize][t[0] as usize] = true; }
        }
        let mut seen = 0u8;
        let mut components = [0u8; MAX_N];
        let mut component_count = 0usize;
        for start in 0..n {
            let bit = 1u8 << start;
            if (mask & bit) == 0 || (seen & bit) != 0 { continue; }
            let mut queue = [0usize; MAX_N];
            let (mut head, mut tail) = (0usize, 1usize);
            let mut component = 0u8;
            queue[0] = start;
            seen |= bit;
            while head < tail {
                let current = queue[head]; head += 1;
                component |= 1u8 << current;
                for other in 0..n {
                    let other_bit = 1u8 << other;
                    if edge[current][other] && (mask & other_bit) != 0 && (seen & other_bit) == 0 {
                        seen |= other_bit; queue[tail] = other; tail += 1;
                    }
                }
            }
            components[component_count] = component;
            component_count += 1;
        }
        if component_count == 1 { compatible = false; break; }
        node_value[node_count] = component_count as i32;
        node_count += 1;
        for i in (0..component_count).rev() { tasks[top] = components[i]; top += 1; }
    }
    let mut words = [0i64; MAX_NODES + 1];
    let word_count;
    if compatible {
        words[0] = node_count as i64;
        for i in 0..node_count { words[i + 1] = if kind[i] == 1 { -(node_value[i] as i64 + 1) } else { node_value[i] as i64 }; }
        word_count = node_count + 1;
    } else { words[0] = 0; word_count = 1; }
    let bytes = word_count * 8;
    if output.is_null() || capacity < bytes { return -2; }
    let out = std::slice::from_raw_parts_mut(output, bytes);
    for i in 0..word_count { write_i64(out, i * 8, words[i]); }
    bytes as i64
}
