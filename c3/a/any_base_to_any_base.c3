module any_base_to_any_base;

// Convert radix digits through checked decimal accumulation.
fn long any_base_to_any_base(long* input, usz length, char* output, usz output_capacity)
    @export("any_base_to_any_base")
{
    if (length < 3 || length > 65) return -1;
    long source_base = input[0];
    long target_base = input[1];
    if (source_base < 2 || source_base > 36 || target_base < 2 || target_base > 36) return -1;
    long value = 0;
    for (usz index = 2; index < length; index++) {
        long digit = input[index];
        if (digit < 0 || digit >= source_base || value > (9223372036854775807 - digit) / source_base) return -1;
        value = value * source_base + digit;
    }
    usz width = 1;
    for (long remaining = value; remaining >= target_base; remaining /= target_base) width++;
    if (output_capacity < width) return -2;
    usz top = 0;
    long remaining = value;
    if (remaining == 0) output[top++] = '0';
    while (remaining > 0) {
        long digit = remaining % target_base;
        output[top++] = (char)(digit < 10 ? '0' + digit : 'A' + digit - 10);
        remaining /= target_base;
    }
    usz left = 0;
    usz right = top - 1;
    while (left < right) {
        char temporary = output[left]; output[left] = output[right]; output[right] = temporary;
        left++; right--;
    }
    return (long)top;
}
