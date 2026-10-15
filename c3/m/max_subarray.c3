module max_subarray;

fn long max_subarray_range(long* values, usz start, usz end)
{
    if (end - start == 1) return values[start];
    usz middle = start + (end - start) / 2;
    long left_best = max_subarray_range(values, start, middle);
    long right_best = max_subarray_range(values, middle, end);
    long running = values[middle - 1];
    long left_suffix = running;
    for (usz index = middle - 1; index > start;) {
        index--;
        running += values[index];
        if (running > left_suffix) left_suffix = running;
    }
    running = values[middle];
    long right_prefix = running;
    for (usz index = middle + 1; index < end; index++) {
        running += values[index];
        if (running > right_prefix) right_prefix = running;
    }
    long crossing = left_suffix + right_prefix;
    long best = left_best > right_best ? left_best : right_best;
    return crossing > best ? crossing : best;
}

fn long max_subarray(long* values, usz length) @export("max_subarray")
{
    if (length == 0 || length > 1024) return -1;
    for (usz index = 0; index < length; index++) {
        if (values[index] < -2147483648 || values[index] > 2147483647) return -1;
    }
    return max_subarray_range(values, 0, length);
}
