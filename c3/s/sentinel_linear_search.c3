module sentinel_linear_search;

fn long sentinel_linear_search(long* values, usz length, long target) @export("sentinel_linear_search")
{
    if (length == 0) return -1;

    usz last_index = length - 1;
    long saved_last = values[last_index];
    if (saved_last == target) return (long)last_index;

    values[last_index] = target;
    usz index = 0;
    while (values[index] != target) index++;
    values[last_index] = saved_last;

    return index == last_index ? -1 : (long)index;
}
