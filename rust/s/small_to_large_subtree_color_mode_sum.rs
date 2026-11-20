const MAX_N: usize = 64;
const CELLS: usize = MAX_N * MAX_N;

fn add_color(map: usize, color: usize, amount: i64, labels: &[i64; MAX_N],
             frequencies: &mut [i64; CELLS], keys: &mut [usize; CELLS],
             lengths: &mut [usize; MAX_N], maximum: &mut [i64; MAX_N],
             mode_sum: &mut [i64; MAX_N]) {
    let cell = map * MAX_N + color;
    let old = frequencies[cell];
    if old == 0 {
        keys[map * MAX_N + lengths[map]] = color;
        lengths[map] += 1;
    }
    if old > 0 && old == maximum[map] { mode_sum[map] -= labels[color]; }
    let updated = old + amount;
    if updated > maximum[map] {
        maximum[map] = updated;
        mode_sum[map] = labels[color];
    } else if updated == maximum[map] {
        mode_sum[map] += labels[color];
    }
    frequencies[cell] = updated;
}

unsafe fn write_word(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    for byte in 0..8 { *output.add(offset + byte) = bytes[byte]; }
}

#[no_mangle]
pub unsafe extern "C" fn small_to_large_subtree_color_mode_sum(
    input_ptr: *const i64, length: usize, output_ptr: *mut u8, capacity: usize,
) -> i64 {
    if input_ptr.is_null() || length < 2 || length > 129 { return -1; }
    let input = std::slice::from_raw_parts(input_ptr, length);
    let n_value = input[0];
    if !(1..=MAX_N as i64).contains(&n_value) || length != 2 * n_value as usize { return -1; }
    let n = n_value as usize;
    let mut parent = [0usize; MAX_N];
    for vertex in 1..n {
        let p = input[vertex];
        if p < 0 || p >= vertex as i64 { return -1; }
        parent[vertex] = p as usize;
    }
    let mut sorted = [0i64; MAX_N];
    for vertex in 0..n {
        let color = input[n + vertex];
        if !(-1000..=1000).contains(&color) { return -1; }
        sorted[vertex] = color;
    }
    sorted[..n].sort_unstable();
    let mut labels = [0i64; MAX_N];
    let mut distinct = 0usize;
    for &color in &sorted[..n] {
        if distinct == 0 || labels[distinct - 1] != color {
            labels[distinct] = color;
            distinct += 1;
        }
    }
    let mut color_index = [0usize; MAX_N];
    for vertex in 0..n {
        let mut index = 0;
        while labels[index] != input[n + vertex] { index += 1; }
        color_index[vertex] = index;
    }
    if output_ptr.is_null() || capacity < 8 * n { return -2; }

    let mut frequencies = [0i64; CELLS];
    let mut keys = [0usize; CELLS];
    let mut map_lengths = [0usize; MAX_N];
    let mut map_id = [0usize; MAX_N];
    let mut maximum = [0i64; MAX_N];
    let mut mode_sum = [0i64; MAX_N];
    let mut answers = [0i64; MAX_N];
    for vertex in (0..n).rev() {
        let mut largest = n;
        for child in vertex + 1..n {
            if parent[child] == vertex &&
                (largest == n || map_lengths[map_id[child]] > map_lengths[map_id[largest]]) {
                largest = child;
            }
        }
        let map = if largest == n { vertex } else { map_id[largest] };
        for child in vertex + 1..n {
            if parent[child] != vertex || child == largest { continue; }
            let small = map_id[child];
            for index in 0..map_lengths[small] {
                let color = keys[small * MAX_N + index];
                let amount = frequencies[small * MAX_N + color];
                add_color(map, color, amount, &labels, &mut frequencies, &mut keys,
                          &mut map_lengths, &mut maximum, &mut mode_sum);
            }
        }
        add_color(map, color_index[vertex], 1, &labels, &mut frequencies, &mut keys,
                  &mut map_lengths, &mut maximum, &mut mode_sum);
        map_id[vertex] = map;
        answers[vertex] = mode_sum[map];
    }
    for vertex in 0..n { write_word(output_ptr, vertex * 8, answers[vertex]); }
    (8 * n) as i64
}
