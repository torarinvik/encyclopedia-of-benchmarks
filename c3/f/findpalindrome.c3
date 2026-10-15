module findpalindrome;
const usz MAX_LENGTH = 4096;
fn bool punctuation(long value) { return (value >= 33 && value <= 47) || (value >= 58 && value <= 64) || (value >= 91 && value <= 96) || (value >= 123 && value <= 126); }
fn long fold(long value) { return value >= 65 && value <= 90 ? value + 32 : value; }
fn long findpalindrome(long* input, usz length, char* output, usz output_capacity) @export("findpalindrome") {
    if (length > MAX_LENGTH || (length != 0 && input == null)) return -1;
    for (usz i = 0; i < length; i++) if (input[i] < 32 || input[i] > 126) return -1;
    usz written = 0;
    usz segment = 0;
    bool found = false;
    for (usz end = 0; end <= length; end++) {
        if (end < length && input[end] != 32) continue;
        usz token_length = 0;
        for (usz i = segment; i < end; i++) if (!punctuation(input[i])) token_length++;
        usz left = segment;
        usz right = end;
        while (left < right) {
            while (left < right && punctuation(input[left])) left++;
            while (left < right && punctuation(input[right - 1])) right--;
            if (left >= right) break;
            if (fold(input[left]) != fold(input[right - 1])) { token_length = 0; break; }
            left++; right--;
        }
        if (token_length > 1) {
            usz needed = token_length;
            if (found) needed++;
            if (written + needed > output_capacity) return -2;
            if (found) { output[written] = 0; written++; }
            for (usz i = segment; i < end; i++) if (!punctuation(input[i])) { output[written] = (char)input[i]; written++; }
            found = true;
        }
        segment = end + 1;
    }
    return (long)written;
}
