module shortest_palindrome;

const usz MAX_INPUT_LENGTH = 64;

fn long shortest_palindrome(long* input, usz length, char* output,
                            usz output_capacity) @export("shortest_palindrome") {
    if (length > MAX_INPUT_LENGTH || (length > 0 && input == null)) return -1;
    for (usz i = 0; i < length; i++) {
        if (input[i] < 32 || input[i] > 126) return -1;
    }
    if (length == 0) return 0;

    usz[64] suffix = zeroed;
    for (usz i = 1; i < length; i++) {
        usz matched = suffix[i - 1];
        while (matched > 0 && input[matched] != input[i]) matched = suffix[matched - 1];
        if (input[matched] == input[i]) matched++;
        suffix[i] = matched;
    }

    usz prefix_match = 0;
    for (usz i = 0; i < length; i++) {
        long reversed_value = input[length - 1 - i];
        while (prefix_match > 0 && reversed_value != input[prefix_match])
            prefix_match = suffix[prefix_match - 1];
        if (reversed_value == input[prefix_match]) prefix_match++;
    }

    usz output_length = 2 * length - prefix_match;
    if (output == null || output_capacity < output_length) return -2;
    for (usz i = 0; i < length; i++) output[i] = (char)input[length - 1 - i];
    for (usz i = prefix_match; i < length; i++)
        output[length + i - prefix_match] = (char)input[i];
    return (long)output_length;
}
