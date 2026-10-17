module big_integer_multiply;

fn long big_integer_multiply(long* input, usz length, char* output, usz capacity)
    @export("big_integer_multiply") {
    if (input == null || length < 4 || length > 66) return -1;
    long left_value = input[0], right_value = input[1];
    if (left_value < 1 || left_value > 32 || right_value < 1 || right_value > 32) return -1;
    usz left_length = (usz)left_value, right_length = (usz)right_value;
    if (length != 2 + left_length + right_length) return -1;
    usz right_start = 2 + left_length;
    for (usz index = 0; index < left_length; index++)
        if (input[2 + index] < 48 || input[2 + index] > 57) return -1;
    for (usz index = 0; index < right_length; index++)
        if (input[right_start + index] < 48 || input[right_start + index] > 57) return -1;
    if ((left_length > 1 && input[2] == 48) ||
        (right_length > 1 && input[right_start] == 48)) return -1;

    long product[64];
    for (usz index = 0; index < 64; index++) product[index] = 0;
    usz product_size = left_length + right_length;
    bool is_zero = (left_length == 1 && input[2] == 48) ||
                   (right_length == 1 && input[right_start] == 48);
    if (!is_zero) {
        for (usz i = 0; i < left_length; i++) {
            for (usz j = 0; j < right_length; j++) {
                usz position = i + j;
                long multiplication = (input[2 + left_length - i - 1] - 48) *
                    (input[right_start + right_length - j - 1] - 48);
                product[position + 1] += (product[position] + multiplication) / 10;
                product[position] = (product[position] + multiplication) % 10;
            }
        }
    }
    usz effective_size = product_size;
    if (is_zero) effective_size = 1;
    else if (product[product_size - 1] == 0) effective_size--;
    if (output == null || capacity < effective_size) return -2;
    if (is_zero) output[0] = '0';
    else for (usz index = 0; index < effective_size; index++)
        output[index] = (char)('0' + product[effective_size - index - 1]);
    return (long)effective_size;
}
