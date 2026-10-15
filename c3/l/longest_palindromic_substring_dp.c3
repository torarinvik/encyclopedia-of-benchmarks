module longest_palindromic_substring_dp;

const MAX_LENGTH = 1000;
extern fn void* malloc(usz size);
extern fn void free(void* pointer);

fn bool is_ascii_alphanumeric(long value)
{
    return (value >= '0' && value <= '9') ||
           (value >= 'A' && value <= 'Z') ||
           (value >= 'a' && value <= 'z');
}

// Find the rightmost longest ASCII alphanumeric palindrome with gap-based DP.
fn long longest_palindromic_substring_dp(long* values, usz length,
                                         char* output, usz output_capacity)
    @export("longest_palindromic_substring_dp")
{
    if (values == null || length == 0 || length > MAX_LENGTH) return -1;
    for (usz index = 0; index < length; index++)
        if (!is_ascii_alphanumeric(values[index])) return -1;

    bool* palindrome = (bool*)malloc(length * length);
    if (palindrome == null) return -1;
    defer free(palindrome);
    usz best_start = 0;
    usz best_end = 0;
    for (usz gap = 0; gap < length; gap++) {
        for (usz start = 0, end = gap; end < length; start++, end++) {
            bool is_palindrome;
            if (gap == 0) {
                is_palindrome = true;
            } else if (gap == 1) {
                is_palindrome = values[start] == values[end];
            } else {
                is_palindrome = values[start] == values[end] && palindrome[(start + 1) * length + end - 1];
            }
            palindrome[start * length + end] = is_palindrome;
            if (is_palindrome) {
                best_start = start;
                best_end = end;
            }
        }
    }

    usz best_length = best_end - best_start + 1;
    if (output == null || output_capacity < best_length) return -2;
    for (usz index = 0; index < best_length; index++)
        output[index] = (char)values[best_start + index];
    return (long)best_length;
}
