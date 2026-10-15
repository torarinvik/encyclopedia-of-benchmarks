module double_linear_search;

const long MAX_ITEMS = 100000;
const long MAX_SAFE_INTEGER = 9007199254740991;

// Two-ended linear search with source-compatible endpoint priority.
fn long double_linear_search_impl(long* values, usz length)
{
    if (values == null || length < 2 || length > 100002) return -1;
    long target = values[0];
    long count_value = values[1];
    if (target < -MAX_SAFE_INTEGER || target > MAX_SAFE_INTEGER ||
        count_value < 0 || count_value > MAX_ITEMS || length != (usz)(count_value + 2)) return -1;
    usz count = (usz)count_value;
    for (usz index = 0; index < count; index++) {
        if (values[index + 2] < -MAX_SAFE_INTEGER || values[index + 2] > MAX_SAFE_INTEGER) return -1;
    }
    usz start = 0, right = count;
    while (start < right) {
        if (values[start + 2] == target) return (long)start;
        if (values[right + 1] == target) return (long)(right - 1);
        start++;
        right--;
    }
    return -1;
}

// Stable C ABI entry point.
fn long double_linear_search(long* values, usz length) @export("double_linear_search")
{
    return double_linear_search_impl(values, length);
}
