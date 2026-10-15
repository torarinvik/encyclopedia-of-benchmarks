module abbreviation;

const usz MAX_STRING_LENGTH = 128;

fn bool is_lower_ascii(long value)
{
    return value >= 'a' && value <= 'z';
}

fn long uppercase_ascii(long value)
{
    return is_lower_ascii(value) ? value - ('a' - 'A') : value;
}

// Check whether lowercase source letters can be capitalized or deleted.
fn long abbreviation(long* values, usz length) @export("abbreviation")
{
    if (length < 2 || length > 258) return -1;
    long source_length = values[0];
    long target_length = values[1];
    if (source_length < 0 || source_length > 128 || target_length < 0 || target_length > 128 ||
        length != (usz)(2 + source_length + target_length)) return -1;
    for (long index = 0; index < source_length; index++) {
        long value = values[2 + (usz)index];
        if (!((value >= 'A' && value <= 'Z') || is_lower_ascii(value))) return -1;
    }
    for (long index = 0; index < target_length; index++) {
        long value = values[2 + (usz)source_length + (usz)index];
        if (value < 'A' || value > 'Z') return -1;
    }

    bool[129] current;
    bool[129] next;
    for (usz index = 0; index <= MAX_STRING_LENGTH; index++) {
        current[index] = false;
        next[index] = false;
    }
    current[0] = true;
    for (long source_index = 0; source_index < source_length; source_index++) {
        for (long target_index = 0; target_index <= target_length; target_index++) {
            next[(usz)target_index] = false;
        }
        long source = values[2 + (usz)source_index];
        long upper = uppercase_ascii(source);
        for (long target_index = 0; target_index <= target_length; target_index++) {
            if (!current[(usz)target_index]) continue;
            if (is_lower_ascii(source)) next[(usz)target_index] = true;
            if (target_index < target_length &&
                upper == values[2 + (usz)source_length + (usz)target_index]) {
                next[(usz)(target_index + 1)] = true;
            }
        }
        for (long target_index = 0; target_index <= target_length; target_index++) {
            current[(usz)target_index] = next[(usz)target_index];
        }
    }
    return current[(usz)target_length] ? 1 : 0;
}
