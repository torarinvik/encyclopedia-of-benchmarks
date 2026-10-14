module interpolation_search;

fn long interpolation_search_impl(long* values, usz length, long target)
{
    if (length == 0) return -1;
    usz low = 0;
    usz high = length - 1;
    while (low <= high)
    {
        long low_value = values[low];
        long high_value = values[high];
        if (target < low_value || target > high_value) return -1;
        if (low_value == high_value) return low_value == target ? (long)low : -1;
        long numerator = (target - low_value) * (long)(high - low);
        long denominator = high_value - low_value;
        usz position = low + (usz)(numerator / denominator);
        long value = values[position];
        if (value == target) return (long)position;
        if (value < target) low = position + 1;
        else
        {
            if (position == 0) return -1;
            high = position - 1;
        }
    }
    return -1;
}

fn long interpolation_search(long* values, usz length, long target) @export("interpolation_search")
{
    return interpolation_search_impl(values, length, target);
}
