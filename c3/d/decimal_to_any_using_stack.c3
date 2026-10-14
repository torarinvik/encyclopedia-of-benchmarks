module decimal_to_any_using_stack;

// Convert a nonnegative signed 64-bit value with a LIFO digit stack.
fn long decimal_to_any_using_stack(long* input, usz length, char* output, usz output_capacity)
    @export("decimal_to_any_using_stack")
{
    if (length != 2) return -1;
    long value = input[0];
    long base = input[1];
    if (value < 0 || base < 2 || base > 16) return -1;
    usz width = 1;
    for (long remaining = value; remaining >= base; remaining /= base) width++;
    if (output_capacity < width) return -2;
    usz top = 0;
    long remaining = value;
    if (remaining == 0) output[top++] = '0';
    while (remaining > 0) {
        long digit = remaining % base;
        output[top++] = (char)(digit < 10 ? '0' + digit : 'A' + digit - 10);
        remaining /= base;
    }
    usz left = 0;
    usz right = top - 1;
    while (left < right) {
        char temporary = output[left];
        output[left] = output[right];
        output[right] = temporary;
        left++;
        right--;
    }
    return (long)top;
}
