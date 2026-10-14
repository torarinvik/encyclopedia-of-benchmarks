module fibonacci_search;

fn long fibonacci_search_impl(long* values, usz length, long target)
{
    if (length == 0) return -1;
    usz fib_minus_two = 0;
    usz fib_minus_one = 1;
    usz fib = 1;
    while (fib < length)
    {
        fib_minus_two = fib_minus_one;
        fib_minus_one = fib;
        fib = fib_minus_two + fib_minus_one;
    }

    usz offset_plus_one = 0;
    while (fib > 1)
    {
        usz index = offset_plus_one + fib_minus_two - 1;
        if (index >= length) index = length - 1;
        long value = values[index];
        if (value == target) return (long)index;
        if (value < target)
        {
            fib = fib_minus_one;
            fib_minus_one = fib_minus_two;
            fib_minus_two = fib - fib_minus_one;
            offset_plus_one = index + 1;
        }
        else
        {
            fib = fib_minus_two;
            fib_minus_one -= fib_minus_two;
            fib_minus_two = fib - fib_minus_one;
        }
    }
    if (fib_minus_one != 0 && offset_plus_one < length && values[offset_plus_one] == target)
        return (long)offset_plus_one;
    return -1;
}

fn long fibonacci_search(long* values, usz length, long target) @export("fibonacci_search")
{
    return fibonacci_search_impl(values, length, target);
}
