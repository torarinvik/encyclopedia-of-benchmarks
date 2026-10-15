module order_agnostic_binary_search;

const long MAX_ITEMS = 99999;

// Binary search over a monotone sequence in either direction.
fn long order_agnostic_binary_search_impl(long* values, usz length)
{
    if (values == null || length < 3 || length > 100001) return -1;
    long target = values[0], count = values[1];
    if (target < -2147483648 || target > 2147483647 || count < 1 || count > MAX_ITEMS || length != (usz)(count + 2)) return -1;
    bool ascending = values[2] < values[(usz)count + 1];
    long start = 0, end = count - 1;
    while (start <= end) {
        long middle = start + (end - start) / 2;
        long value = values[(usz)middle + 2];
        if (value == target) return middle;
        if (ascending) {
            if (value < target) start = middle + 1;
            else end = middle - 1;
        } else {
            if (value > target) start = middle + 1;
            else end = middle - 1;
        }
    }
    return -1;
}

fn long order_agnostic_binary_search(long* values, usz length) @export("order_agnostic_binary_search")
{
    return order_agnostic_binary_search_impl(values, length);
}
