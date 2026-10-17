module mul_array;

const usz MAX_INPUT_LENGTH = 9;

fn long mul_array(long* values, usz length) @export("mul_array") {
    if (length > MAX_INPUT_LENGTH) return -1;
    if (length == 0) return 1;
    if (values == null) return -1;

    long product = 1;
    for (usz index = 0; index < length; index++) {
        long value = values[index];
        if (value < 0 || value > 99) return -1;
        product *= value;
    }
    return product;
}
