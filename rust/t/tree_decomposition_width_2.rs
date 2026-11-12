const MAX_N: usize = 32;
const MAX_M: usize = 64;
const MAX_INPUT: usize = 131;
const MAX_OUTPUT: usize = 1592;

fn put_i64(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn tree_decomposition_width_2(
    values: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let n0 = input[0];
    let m0 = input[1];
    if !(1..=MAX_N as i64).contains(&n0) || !(0..=MAX_M as i64).contains(&m0) { return -1; }
    let n = n0 as usize;
    let m = m0 as usize;
    if m > n * (n - 1) / 2 || length != 2 + 2 * m { return -1; }

    let mut adjacent = [[false; MAX_N]; MAX_N];
    for edge in 0..m {
        let left0 = input[2 + 2 * edge];
        let right0 = input[3 + 2 * edge];
        if left0 < 0 || left0 >= right0 || right0 >= n0 { return -1; }
        let (left, right) = (left0 as usize, right0 as usize);
        if adjacent[left][right] { return -1; }
        adjacent[left][right] = true;
        adjacent[right][left] = true;
    }

    let mut active = [false; MAX_N];
    active[..n].fill(true);
    let mut order = [0usize; MAX_N];
    let mut bags = [[-1i64; 3]; MAX_N];
    let mut bag_sizes = [0usize; MAX_N];
    let mut later = [[0usize; 2]; MAX_N];
    let mut later_counts = [0usize; MAX_N];
    for step in 0..n {
        let mut chosen = usize::MAX;
        let mut neighbors = [0usize; 2];
        let mut count = 0usize;
        for vertex in 0..n {
            if !active[vertex] { continue; }
            let degree = (0..n).filter(|&other| active[other] && adjacent[vertex][other]).count();
            if degree <= 2 {
                chosen = vertex;
                for other in 0..n {
                    if active[other] && adjacent[vertex][other] {
                        neighbors[count] = other;
                        count += 1;
                    }
                }
                break;
            }
        }
        if chosen == usize::MAX { return -1; }
        order[step] = chosen;
        later[step][..count].copy_from_slice(&neighbors[..count]);
        later_counts[step] = count;
        let mut contents = [chosen as i64, -1, -1];
        for i in 0..count { contents[i + 1] = neighbors[i] as i64; }
        for i in 0..(count + 1) {
            for j in (i + 1)..(count + 1) {
                if contents[j] < contents[i] { contents.swap(i, j); }
            }
        }
        bags[step] = contents;
        bag_sizes[step] = count + 1;
        if count == 2 {
            adjacent[neighbors[0]][neighbors[1]] = true;
            adjacent[neighbors[1]][neighbors[0]] = true;
        }
        active[chosen] = false;
    }

    let mut position = [0usize; MAX_N];
    for step in 0..n { position[order[step]] = step; }
    let mut parents = [n; MAX_N];
    for step in 0..n {
        if later_counts[step] > 0 {
            let mut selected = later[step][0];
            if later_counts[step] == 2 && position[later[step][1]] < position[selected] {
                selected = later[step][1];
            }
            parents[step] = position[selected];
        }
    }

    let bytes = 8 * (6 * n + 7);
    if output.is_null() || capacity < bytes || bytes > MAX_OUTPUT { return -2; }
    let mut staged = [0u8; MAX_OUTPUT];
    put_i64(&mut staged, 0, (n + 1) as i64);
    put_i64(&mut staged, 8, 2);
    put_i64(&mut staged, 16, n as i64);
    let mut cursor = 24;
    for bag in 0..=n {
        let size = if bag == n { 0 } else { bag_sizes[bag] };
        put_i64(&mut staged, cursor, size as i64);
        cursor += 8;
        for slot in 0..3 {
            let value = if slot < size { bags[bag][slot] } else { -1 };
            put_i64(&mut staged, cursor, value);
            cursor += 8;
        }
    }
    for child in 0..n {
        put_i64(&mut staged, cursor, child as i64);
        put_i64(&mut staged, cursor + 8, parents[child] as i64);
        cursor += 16;
    }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, bytes);
    bytes as i64
}
