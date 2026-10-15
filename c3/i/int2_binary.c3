module int2_binary;

// Encode the C# uint overload as exactly 32 ASCII binary digits.
fn long int2_binary(long value, char* output, usz output_capacity) @export("int2_binary")
{
    if (value < 0 || value > 4294967295) return -1;
    if (output == null || output_capacity < 32) return -2;

    uint remaining = (uint)value;
    uint most_significant_bit = 0x80000000;
    for (usz i = 0; i < 32; i++) {
        if (remaining >= most_significant_bit) {
            output[i] = '1';
            remaining -= most_significant_bit;
        } else {
            output[i] = '0';
        }
        most_significant_bit /= 2;
    }
    return 32;
}
