module count_char;

const long MAX_LENGTH = 4096;

fn long count_char_impl(long* values, usz length)
{
    if (length > MAX_LENGTH || (length != 0 && values == null)) return -1;
    long count = 0;
    for (usz i = 0; i < length; i++) {
        long code = values[i];
        if (code < 0 || code > 127) return -1;
        if (code != 9 && code != 10 && code != 11 && code != 12 && code != 13 && code != 32) count++;
    }
    return count;
}

fn long count_char(long* values, usz length) @export("count_char")
{
    return count_char_impl(values, length);
}
