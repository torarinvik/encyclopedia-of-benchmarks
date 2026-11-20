const MAX_SAMPLES: usize = 8;
const MAX_CELL_VERTICES: usize = 8;

fn store_i64_le(out: &mut [u8], word: usize, value: i64) {
    out[word * 8..word * 8 + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn crust_opposite_pole_selection(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(1..=226).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_raw = values[0];
    if !(1..=8).contains(&n_raw) { return -1; }
    let n = n_raw as usize;
    let mut samples = [[0i64; 3]; MAX_SAMPLES];
    let mut answer = [[0i64; 2]; MAX_SAMPLES];
    let mut offset = 1usize;
    for row in 0..n {
        if offset + 4 > length { return -1; }
        let sample = [values[offset], values[offset + 1], values[offset + 2]];
        let count_raw = values[offset + 3];
        offset += 4;
        if !(1..=8).contains(&count_raw) || sample.iter().any(|&x| !(-16..=16).contains(&x)) { return -1; }
        if samples[..row].contains(&sample) { return -1; }
        samples[row] = sample;
        let count = count_raw as usize;
        if offset + 3 * count > length { return -1; }
        let mut cell = [[0i64; 3]; MAX_CELL_VERTICES];
        for vertex in 0..count {
            for axis in 0..3 {
                cell[vertex][axis] = values[offset]; offset += 1;
                if !(-16..=16).contains(&cell[vertex][axis]) { return -1; }
            }
            if cell[vertex] == sample || cell[..vertex].contains(&cell[vertex]) { return -1; }
        }
        let mut positive = 0usize;
        let mut positive_distance = -1i64;
        for vertex in 0..count {
            let distance: i64 = (0..3).map(|a| (cell[vertex][a] - sample[a]).pow(2)).sum();
            if distance > positive_distance { positive_distance = distance; positive = vertex; }
        }
        let forward = [
            cell[positive][0] - sample[0],
            cell[positive][1] - sample[1],
            cell[positive][2] - sample[2],
        ];
        let mut negative = -1i64;
        let mut negative_distance = -1i64;
        for vertex in 0..count {
            let delta = [cell[vertex][0] - sample[0], cell[vertex][1] - sample[1], cell[vertex][2] - sample[2]];
            let projection = delta[0] * forward[0] + delta[1] * forward[1] + delta[2] * forward[2];
            let distance = delta[0] * delta[0] + delta[1] * delta[1] + delta[2] * delta[2];
            if projection < 0 && distance > negative_distance { negative_distance = distance; negative = vertex as i64; }
        }
        answer[row] = [positive as i64, negative];
    }
    if offset != length { return -1; }
    let bytes = 8 * (1 + 2 * n);
    if output.is_null() || capacity < bytes { return -2; }
    let out = std::slice::from_raw_parts_mut(output, bytes);
    store_i64_le(out, 0, n_raw);
    let mut word = 1;
    for row in 0..n { store_i64_le(out, word, answer[row][0]); word += 1; store_i64_le(out, word, answer[row][1]); word += 1; }
    bytes as i64
}
