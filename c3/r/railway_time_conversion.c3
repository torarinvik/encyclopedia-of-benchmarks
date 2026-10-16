module railway_time_conversion;

const usz MAX_INPUT_LENGTH = 10;
const usz PACKED_INPUT_LENGTH = MAX_INPUT_LENGTH + 1;
const usz OUTPUT_LENGTH = 8;

fn bool is_digit(long value) {
    return value >= 48 && value <= 57;
}

fn long railway_time_conversion(long* values, usz length, char* output, usz output_capacity)
    @export("railway_time_conversion") {
    if (values == null || length != PACKED_INPUT_LENGTH ||
        values[0] != (long)MAX_INPUT_LENGTH) return -1;

    if (values[3] != 58 || values[6] != 58 ||
        !((values[9] == 65 && values[10] == 77) ||
          (values[9] == 80 && values[10] == 77)) ||
        !is_digit(values[1]) || !is_digit(values[2]) ||
        !is_digit(values[4]) || !is_digit(values[5]) ||
        !is_digit(values[7]) || !is_digit(values[8])) return -1;

    hour: long = (values[1] - 48) * 10 + values[2] - 48;
    minute: long = (values[4] - 48) * 10 + values[5] - 48;
    second: long = (values[7] - 48) * 10 + values[8] - 48;
    if (hour < 1 || hour > 12 || minute > 59 || second > 59) return -1;
    if (output == null || output_capacity < OUTPUT_LENGTH) return -2;

    hour24: long = hour % 12 + (if values[9] == 80 then 12 else 0);
    output[0] = (48 + hour24 / 10).u8();
    output[1] = (48 + hour24 % 10).u8();
    output[2] = 58;
    output[3] = values[4].u8();
    output[4] = values[5].u8();
    output[5] = 58;
    output[6] = values[7].u8();
    output[7] = values[8].u8();
    (long)OUTPUT_LENGTH
}
