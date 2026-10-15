module duplicate_zeros;

fn void write_i32(char* output, usz position, long value)
{
    long encoded = value;
    output[position] = (char)(encoded & 255);
    output[position + 1] = (char)((encoded >> 8) & 255);
    output[position + 2] = (char)((encoded >> 16) & 255);
    output[position + 3] = (char)((encoded >> 24) & 255);
}

// Duplicate each zero while retaining the fixed output length.
fn long duplicate_zeros(long* values, usz length, char* output, usz output_capacity) @export("duplicate_zeros")
{
    if (length > 64) return -1;
    for (usz index = 0; index < length; index++) {
        if (values[index] < 0 || values[index] > 1000) return -1;
    }
    usz required = 4 * length;
    if (output_capacity < required || (required > 0 && output == null)) return -2;
    usz source = 0;
    usz destination = 0;
    while (destination < length) {
        long value = values[source++];
        write_i32(output, 4 * destination++, value);
        if (value == 0 && destination < length) write_i32(output, 4 * destination++, 0);
    }
    return (long)length;
}
