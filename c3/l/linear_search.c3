module linear_search;

// Local implementation of the shared first-match linear-search contract.
fn long linear_search_impl(long* values, usz length, long target)
{
    for (usz index = 0; index < length; index++) {
        if (values[index] == target) {
            return (long)index;
        }
    }

    return -1;
}

// Stable C ABI entry point used by the common benchmark runner.
fn long linear_search(long* values, usz length, long target) @export("linear_search")
{
    return linear_search_impl(values, length, target);
}
