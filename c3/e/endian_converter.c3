module endian_converter;
const long INVALID_RESULT = -2147483649L;
// Reverse the byte order of a signed 32-bit integer.
fn long endian_converter(long value) @export("endian_converter") {
    if (value < -2147483648L || value > 2147483647L) return INVALID_RESULT;
    uint bits = (uint)value;
    uint reversed = ((bits & 0x000000FF) << 24) | ((bits & 0x0000FF00) << 8) |
                    ((bits & 0x00FF0000) >> 8) | ((bits & 0xFF000000) >> 24);
    if (reversed <= 0x7FFFFFFF) return (long)reversed;
    return (long)reversed - 4294967296L;
}
