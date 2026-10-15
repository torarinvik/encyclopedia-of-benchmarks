module sorted_arrays_intersection;

const ARRAY_COUNT: usz = 3;
const MAX_ARRAY_LENGTH: usz = 64;
const BYTES_PER_VALUE: usz = 4;

fn void store_i32_le(char* output, usz position, long value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < BYTES_PER_VALUE; byte++)
        output[position + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn long sorted_arrays_intersection(long* input, usz length, char* output, usz output_capacity)
    @export("sorted_arrays_intersection") {
    if (input == null || length < ARRAY_COUNT || length > ARRAY_COUNT * (MAX_ARRAY_LENGTH + 1)) return -1;
    usz[ARRAY_COUNT] starts, sizes;
    usz position = 0;
    for (usz array = 0; array < ARRAY_COUNT; array++) {
        if (position >= length || input[position] < 0 || input[position] > (long)MAX_ARRAY_LENGTH) return -1;
        usz size = (usz)input[position++];
        if (size > length - position) return -1;
        starts[array] = position; sizes[array] = size;
        for (usz index = 0; index < size; index++) {
            if (input[position + index] < -2147483648L || input[position + index] > 2147483647L) return -1;
            if (index > 0 && input[position + index - 1] >= input[position + index]) return -1;
        }
        position += size;
    }
    if (position != length) return -1;
    usz maximum_result = sizes[0] < sizes[1] ? sizes[0] : sizes[1];
    if (sizes[2] < maximum_result) maximum_result = sizes[2];
    if (output_capacity < maximum_result * BYTES_PER_VALUE || (maximum_result != 0 && output == null)) return -2;

    usz[ARRAY_COUNT] cursor = {0};
    usz result_count = 0;
    while (cursor[0] < sizes[0] && cursor[1] < sizes[1] && cursor[2] < sizes[2]) {
        long first = input[starts[0] + cursor[0]];
        long second = input[starts[1] + cursor[1]];
        long third = input[starts[2] + cursor[2]];
        if (first == second && first == third) {
            store_i32_le(output, result_count * BYTES_PER_VALUE, first);
            result_count++;
            cursor[0]++; cursor[1]++; cursor[2]++;
        } else if (first < second) {
            cursor[0]++;
        } else if (second < third) {
            cursor[1]++;
        } else {
            cursor[2]++;
        }
    }
    return (long)result_count;
}
