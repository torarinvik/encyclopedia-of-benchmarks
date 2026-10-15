module adaline_learning;

const usz MAX_SAMPLES = 32;
const usz MAX_FEATURES = 8;

fn void store_i32_le(char* output, usz offset, long value) {
    uint bits = (uint)(int)value;
    for (usz byte = 0; byte < 4; byte++) output[offset + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn long adaline_learning(long* input, usz length, char* output, usz output_capacity) @export("adaline_learning") {
    if (input == null || length < 5) return -1;
    if (input[0] < 1 || input[0] > 32 || input[1] < 1 || input[1] > 8 ||
        input[2] < 1 || input[3] < 1 || input[3] > 12 || input[4] < 1 || input[4] > 500) return -1;

    usz sample_count = (usz)input[0];
    usz feature_count = (usz)input[1];
    long eta_numerator = input[2];
    usz eta_shift = (usz)input[3];
    usz max_iterations = (usz)input[4];
    long scale = 1;
    for (usz bit = 0; bit < eta_shift; bit++) scale *= 2;
    if (eta_numerator >= scale || length != 5 + sample_count * (feature_count + 1)) return -1;

    for (usz sample = 0; sample < sample_count; sample++) {
        usz row = 5 + sample * (feature_count + 1);
        for (usz feature = 0; feature < feature_count; feature++) {
            if (input[row + feature] < -16 || input[row + feature] > 16) return -1;
        }
        long label = input[row + feature_count];
        if (label != -1 && label != 1) return -1;
    }

    usz byte_count = 4 * (1 + feature_count + 1 + sample_count);
    if (output_capacity < byte_count || output == null) return -2;

    long[MAX_FEATURES] weights;
    for (usz feature = 0; feature < feature_count; feature++) weights[feature] = scale;
    long bias = scale;
    usz iterations = 0;
    for (; iterations < max_iterations; iterations++) {
        usz mistakes = 0;
        for (usz sample = 0; sample < sample_count; sample++) {
            usz row = 5 + sample * (feature_count + 1);
            long score = bias;
            for (usz feature = 0; feature < feature_count; feature++) {
                score += input[row + feature] * weights[feature];
            }
            long prediction = score > 0 ? 1 : -1;
            long error = input[row + feature_count] - prediction;
            if (error != 0) {
                mistakes++;
                long correction = eta_numerator * error;
                for (usz feature = 0; feature < feature_count; feature++) {
                    weights[feature] += correction * input[row + feature];
                }
                bias += correction;
            }
        }
        if (mistakes == 0) { iterations++; break; }
    }

    usz position = 0;
    store_i32_le(output, position, (long)iterations); position += 4;
    for (usz feature = 0; feature < feature_count; feature++) {
        store_i32_le(output, position, weights[feature]); position += 4;
    }
    store_i32_le(output, position, bias); position += 4;
    for (usz sample = 0; sample < sample_count; sample++) {
        usz row = 5 + sample * (feature_count + 1);
        long score = bias;
        for (usz feature = 0; feature < feature_count; feature++) {
            score += input[row + feature] * weights[feature];
        }
        store_i32_le(output, position, score > 0 ? 1 : -1);
        position += 4;
    }
    return (long)byte_count;
}
