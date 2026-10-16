module iterative_ternary_search;

fn long iterative_ternary_search(long* packed, usz length) @export("iterative_ternary_search")
{
    if (length < 2) return -1;
    long target = packed[0];
    long* array = packed + 1;
    usz array_length = length - 1;
    if (array_length == 1) return array[0] == target ? 0 : -1;

    usz left = 0;
    usz right = array_length - 1;
    while (right > left)
    {
        if (array[left] == target) return (long)left;
        if (array[right] == target) return (long)right;
        usz left_third = left + (right - left) / 3 + 1;
        usz right_third = right - (right - left) / 3 - 1;
        if (array[left_third] <= target) left = left_third;
        else right = right_third;
    }
    return -1;
}
