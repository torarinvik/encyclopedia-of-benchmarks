module matrix_equalization;

const usz MAX_VECTOR_LENGTH = 64;
const usz MAX_INPUT_LENGTH = 66;

// Minimum updates needed to equalize a vector with a fixed step size.
fn long matrix_equalization(long* input, usz length) @export("matrix_equalization") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    usz vector_length = length - 1;
    if (vector_length > MAX_VECTOR_LENGTH || input[0] < 1 ||
        input[0] > (long)vector_length) return -1;
    usz step_size = (usz)input[0];
    usz minimum_updates = vector_length;

    for (usz target_index = 0; target_index < vector_length; target_index++) {
        bool seen = false;
        for (usz previous = 0; previous < target_index; previous++) {
            if (input[previous + 1] == input[target_index + 1]) {
                seen = true;
                break;
            }
        }
        if (seen) continue;

        usz updates = 0;
        usz index = 0;
        while (index < vector_length) {
            if (input[index + 1] == input[target_index + 1]) {
                index++;
            } else {
                updates++;
                index += step_size;
            }
        }
        if (updates < minimum_updates) minimum_updates = updates;
    }
    return (long)minimum_updates;
}
