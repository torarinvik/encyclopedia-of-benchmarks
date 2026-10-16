module byte_encoding_utils;

// Reverse the eight bytes in a 64-bit bit pattern.
fn long byte_encoding_utils(long value) @export("byte_encoding_utils") {
    ulong bits = (ulong)value;
    ulong reversed = ((bits & 0x00000000000000FF) << 56) |
                     ((bits & 0x000000000000FF00) << 40) |
                     ((bits & 0x0000000000FF0000) << 24) |
                     ((bits & 0x00000000FF000000) << 8) |
                     ((bits & 0x000000FF00000000) >> 8) |
                     ((bits & 0x0000FF0000000000) >> 24) |
                     ((bits & 0x00FF000000000000) >> 40) |
                     ((bits & 0xFF00000000000000) >> 56);
    if (reversed <= 0x7FFFFFFFFFFFFFFF) return (long)reversed;
    return -1L - (long)(0xFFFFFFFFFFFFFFFF - reversed);
}
