module shuffle;

const usz MAX_LENGTH = 256;
const usz MAX_PARSEABLE_INPUT_LENGTH = 513;

fn bool finite_value(double value) {
    return value == value && value >= -1e308 && value <= 1e308;
}

fn bool exact_integer_in_range(double value, long minimum, long maximum, long* integer) {
    if (!finite_value(value) || value < (double)minimum || value > (double)maximum) return false;
    long converted = (long)value;
    if ((double)converted != value) return false;
    *integer = converted;
    return true;
}

fn long shuffle(double* input, usz input_length, double* output, usz output_capacity)
    @export("shuffle") {
    if (input == null || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;

    long count_value;
    if (!exact_integer_in_range(input[0], 0, (long)MAX_LENGTH, &count_value)) return -1L;
    usz count = (usz)count_value;
    usz offset_count = count > 0 ? count - 1 : 0;
    usz expected_length = 1 + count + offset_count;
    if (input_length != expected_length) return -1L;

    long[MAX_LENGTH] values = zeroed;
    usz[MAX_LENGTH] offsets = zeroed;
    for (usz index = 0; index < count; index++) {
        long value;
        if (!exact_integer_in_range(input[1 + index], -2147483648L, 2147483647L, &value)) return -1L;
        values[index] = value;
    }
    for (usz index = 0; index < offset_count; index++) {
        long offset;
        long maximum_offset = (long)(count - 1 - index);
        if (!exact_integer_in_range(input[1 + count + index], 0, maximum_offset, &offset)) return -1L;
        offsets[index] = (usz)offset;
    }

    if (output == null || output_capacity < count) return -2L;
    for (usz index = 0; index < offset_count; index++) {
        usz other = index + offsets[index];
        long temporary = values[index];
        values[index] = values[other];
        values[other] = temporary;
    }
    for (usz index = 0; index < count; index++) output[index] = (double)values[index];
    return (long)count;
}
