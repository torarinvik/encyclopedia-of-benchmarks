const MAX_PARSEABLE_INPUT_LENGTH: usize = 2020;
const MAX_OUTPUT_BYTES: usize = 4096;
const DRAW_SCALE: i64 = 1_i64 << 53;
const MIN_PROBABILITY_UNITS: i64 = -(1_i64 << 53);
const MAX_PROBABILITY_UNITS: i64 = 1_i64 << 54;

#[no_mangle]
pub unsafe extern "C" fn random_graph_generator(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 3 || input_length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if !(0..=64).contains(&values[0]) || !(values[1] == 0 || values[1] == 1)
        || !(MIN_PROBABILITY_UNITS..=MAX_PROBABILITY_UNITS).contains(&values[2]) { return -1; }
    let vertex_count = values[0] as usize;
    let directed = values[1];
    let probability_units = values[2];
    let pair_count = if vertex_count < 2 { 0 } else { vertex_count * (vertex_count - 1) / 2 };
    let draw_count = if probability_units > 0 && probability_units < DRAW_SCALE { pair_count } else { 0 };
    if input_length != 3 + draw_count { return -1; }
    for &draw in &values[3..] {
        if !(0..DRAW_SCALE).contains(&draw) { return -1; }
    }

    let mut staged = [0_u8; MAX_OUTPUT_BYTES];
    if probability_units >= DRAW_SCALE {
        for source in 0..vertex_count {
            for target in 0..vertex_count {
                if source != target { staged[source * vertex_count + target] = 1; }
            }
        }
    } else if probability_units > 0 {
        let mut draw_index = 0_usize;
        for source in 0..vertex_count {
            for target in source + 1..vertex_count {
                if values[3 + draw_index] < probability_units {
                    staged[source * vertex_count + target] = 1;
                    if directed == 0 { staged[target * vertex_count + source] = 1; }
                }
                draw_index += 1;
            }
        }
    }

    let output_bytes = vertex_count * vertex_count;
    if output.is_null() || output_capacity < output_bytes { return -2; }
    if output_bytes > 0 {
        std::ptr::copy_nonoverlapping(staged.as_ptr(), output, output_bytes);
    }
    output_bytes as i64
}
