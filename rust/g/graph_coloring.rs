const MAX_VERTICES: usize = 8;
const MAX_COLORS: i64 = 4;
const MAX_VALIDATION_LENGTH: usize = 11;
const OUTPUT_BYTES: usize = 8;

fn count_from(masks: &[u8; MAX_VERTICES], colors: &mut [u8; MAX_VERTICES],
              vertex_count: usize, color_count: usize, vertex: usize) -> i64 {
    if vertex == vertex_count { return 1; }
    let mut count = 0i64;
    for color in 0..color_count {
        let mut safe = true;
        for prior in 0..vertex {
            if (masks[vertex] & (1u8 << prior)) != 0 && usize::from(colors[prior]) == color {
                safe = false;
                break;
            }
        }
        if safe {
            colors[vertex] = color as u8;
            count += count_from(masks, colors, vertex_count, color_count, vertex + 1);
        }
    }
    count
}

#[no_mangle]
pub unsafe extern "C" fn graph_coloring(input: *const i64, length: usize,
                                           output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_VALIDATION_LENGTH { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    if !(1..=MAX_VERTICES as i64).contains(&n64) || !(1..=MAX_COLORS).contains(&m64) { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    if length != n + 2 { return -1; }

    let mut masks = [0u8; MAX_VERTICES];
    for vertex in 0..n {
        let row = *input.add(2 + vertex);
        if row < 0 || row >= (1i64 << n) { return -1; }
        masks[vertex] = row as u8;
        if (masks[vertex] & (1u8 << vertex)) != 0 { return -1; }
    }
    for vertex in 0..n {
        for neighbor in 0..n {
            let edge = (masks[vertex] & (1u8 << neighbor)) != 0;
            let reverse_edge = (masks[neighbor] & (1u8 << vertex)) != 0;
            if edge != reverse_edge { return -1; }
        }
    }
    if output.is_null() || capacity < OUTPUT_BYTES { return -2; }

    let mut colors = [0u8; MAX_VERTICES];
    let count = count_from(&masks, &mut colors, n, m, 0) as u64;
    for (byte, value) in count.to_le_bytes().iter().enumerate() { *output.add(byte) = *value; }
    OUTPUT_BYTES as i64
}
