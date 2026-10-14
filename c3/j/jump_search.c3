module jump_search;

fn usz integer_sqrt(usz value)
{
    if (value < 2) return value;
    usz low = 1;
    usz high = value / 2 + 1;
    usz result = 1;
    while (low <= high)
    {
        usz middle = low + (high - low) / 2;
        if (middle <= value / middle)
        {
            result = middle;
            low = middle + 1;
        }
        else high = middle - 1;
    }
    return result;
}

fn long jump_search_impl(long* values, usz length, long target)
{
    if (length == 0) return -1;
    usz step = integer_sqrt(length);
    usz block_start = 0;
    usz block_end = step < length ? step : length;
    while (values[block_end - 1] < target)
    {
        if (block_end == length) return -1;
        block_start = block_end;
        block_end = step > length - block_end ? length : block_end + step;
    }
    for (usz index = block_start; index < block_end; index++)
    {
        if (values[index] == target) return (long)index;
        if (values[index] > target) return -1;
    }
    return -1;
}

fn long jump_search(long* values, usz length, long target) @export("jump_search")
{
    return jump_search_impl(values, length, target);
}
