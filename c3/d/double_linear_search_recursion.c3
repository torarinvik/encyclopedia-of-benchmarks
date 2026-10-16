module double_linear_search_recursion;

const long MAX_ITEMS = 1024;
const long INVALID_RESULT = -2;

fn long search_range(long* values, long key, long left, long right, usz offset)
{
    if (left > right) return -1;
    if (values[offset + (usz)left] == key) return left;
    if (values[offset + (usz)right] == key) return right;
    return search_range(values, key, left + 1, right - 1, offset);
}

fn long double_linear_search_recursion(long* input, usz length) @export("double_linear_search_recursion")
{
    if (input == null || length < 2 || length > 1026) return INVALID_RESULT;
    long count = input[0], key = input[1];
    if (count < 0 || count > MAX_ITEMS || key < -2147483648 || key > 2147483647 ||
        length != (usz)(2 + count)) return INVALID_RESULT;
    for (long index = 0; index < count; index++) {
        if (input[2 + index] < -2147483648 || input[2 + index] > 2147483647) return INVALID_RESULT;
    }
    return search_range(input, key, 0, count - 1, 2);
}
