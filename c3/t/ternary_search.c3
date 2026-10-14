module ternary_search;

fn long ternary_search_impl(long* values, usz length, long target)
{
    usz low = 0;
    usz high = length;
    while (low < high)
    {
        usz third = (high - low) / 3;
        usz first = low + third;
        usz second = high - third - 1;
        long first_value = values[first];
        long second_value = values[second];
        if (first_value == target) return (long)first;
        if (second_value == target) return (long)second;
        if (target < first_value) high = first;
        else if (target > second_value) low = second + 1;
        else
        {
            low = first + 1;
            high = second;
        }
    }
    return -1;
}

fn long ternary_search(long* values, usz length, long target) @export("ternary_search")
{
    return ternary_search_impl(values, length, target);
}
