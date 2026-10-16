module cosine_similarity;

extern fn double sqrt(double value);

const usz MAX_STRING_LENGTH = 64;
const usz MAX_INPUT_LENGTH = 132;
const usz ALPHABET_SIZE = 95;
const double INVALID_RESULT = -1.0e300;

fn double cosine_similarity(long* input, usz length) @export("cosine_similarity") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    if (input[0] < 0 || input[0] > (long)MAX_STRING_LENGTH
            || input[1] < 0 || input[1] > (long)MAX_STRING_LENGTH) return INVALID_RESULT;
    usz left_length = (usz)input[0];
    usz right_length = (usz)input[1];
    if (length != 2 + left_length + right_length) return INVALID_RESULT;

    usz[ALPHABET_SIZE] left_counts = zeroed;
    usz[ALPHABET_SIZE] right_counts = zeroed;
    for (usz i = 0; i < left_length; i++) {
        long value = input[2 + i];
        if (value < 32 || value > 126) return INVALID_RESULT;
        if (value >= 65 && value <= 90) value += 32;
        left_counts[(usz)(value - 32)]++;
    }
    for (usz i = 0; i < right_length; i++) {
        long value = input[2 + left_length + i];
        if (value < 32 || value > 126) return INVALID_RESULT;
        if (value >= 65 && value <= 90) value += 32;
        right_counts[(usz)(value - 32)]++;
    }

    double dot_product = 0.0;
    double left_magnitude_squared = 0.0;
    double right_magnitude_squared = 0.0;
    for (usz i = 0; i < ALPHABET_SIZE; i++) {
        double left = (double)left_counts[i];
        double right = (double)right_counts[i];
        dot_product += left * right;
        left_magnitude_squared += left * left;
        right_magnitude_squared += right * right;
    }
    if (left_magnitude_squared <= 0.0 || right_magnitude_squared <= 0.0) return 0.0;
    return dot_product / (sqrt(left_magnitude_squared) * sqrt(right_magnitude_squared));
}
