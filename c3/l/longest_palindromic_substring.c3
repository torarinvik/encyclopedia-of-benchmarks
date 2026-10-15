module longest_palindromic_substring;

fn bool is_ascii_alphanumeric(long value)
{
    return (value >= '0' && value <= '9') ||
           (value >= 'A' && value <= 'Z') ||
           (value >= 'a' && value <= 'z');
}

// Find the leftmost longest ASCII alphanumeric palindrome by expanding centers.
fn long longest_palindromic_substring(long* values, usz length,
                                      char* output, usz output_capacity)
    @export("longest_palindromic_substring")
{
    if (length == 0 || length > 1000 || values == null) {
        return -1;
    }
    for (usz index = 0; index < length; index++) {
        if (!is_ascii_alphanumeric(values[index])) {
            return -1;
        }
    }

    usz best_start = 0;
    usz best_length = 1;
    for (usz center = 0; center < length; center++) {
        usz left = center;
        usz right = center;
        while (left > 0 && right + 1 < length &&
               values[left - 1] == values[right + 1]) {
            left--;
            right++;
        }
        usz candidate_length = right - left + 1;
        if (candidate_length > best_length) {
            best_start = left;
            best_length = candidate_length;
        }

        left = center;
        right = center + 1;
        while (right < length && values[left] == values[right]) {
            candidate_length = right - left + 1;
            if (candidate_length > best_length) {
                best_start = left;
                best_length = candidate_length;
            }
            if (left == 0 || right + 1 == length) {
                break;
            }
            left--;
            right++;
        }
    }

    if (output_capacity < best_length || output == null) {
        return -2;
    }
    for (usz index = 0; index < best_length; index++) {
        output[index] = (char)values[best_start + index];
    }
    return (long)best_length;
}
