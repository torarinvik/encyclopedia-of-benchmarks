/// Minimum updates needed to equalize a vector with a fixed step size.
#[no_mangle]
pub extern "C" fn matrix_equalization(input: *const i64, length: usize) -> i64 {
    const MAX_VECTOR_LENGTH: usize = 64;
    const MAX_INPUT_LENGTH: usize = MAX_VECTOR_LENGTH + 2;
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    let vector_length = length - 1;
    if vector_length > MAX_VECTOR_LENGTH || input[0] < 1 || input[0] > vector_length as i64 {
        return -1;
    }
    let step_size = input[0] as usize;
    let mut minimum_updates = vector_length;

    for target_index in 0..vector_length {
        if input[1..1 + target_index].contains(&input[target_index + 1]) {
            continue;
        }

        let mut updates = 0usize;
        let mut index = 0usize;
        while index < vector_length {
            if input[index + 1] == input[target_index + 1] {
                index += 1;
            } else {
                updates += 1;
                index += step_size;
            }
        }
        minimum_updates = minimum_updates.min(updates);
    }
    minimum_updates as i64
}
