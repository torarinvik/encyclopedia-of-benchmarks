module valid_anagram;

const ulong MAX_STRING_LENGTH = 1024;
const usz MAX_INPUT_LENGTH = 2050;

fn long valid_anagram(long* input, usz length) @export("valid_anagram") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    ulong first = (ulong)input[0];
    ulong second = (ulong)input[1];
    if (first > MAX_STRING_LENGTH || second > MAX_STRING_LENGTH ||
        length != 2 + first + second) return -1;
    if (first != second) {
        for (usz i = 2; i < length; ++i) {
            if ((ulong)input[i] - 97 > 25) return -1;
        }
        return 0;
    }

    ushort[26] counts;
    usz count = (usz)first;
    for (usz i = 2; i < 2 + count; ++i) {
        ulong left = (ulong)input[i] - 97;
        ulong right = (ulong)input[i + count] - 97;
        if (left > 25 || right > 25) return -1;
        if (left != right) {
            ++counts[left];
            --counts[right];
        }
    }
    for (usz slot = 0; slot < 26; ++slot) {
        if (counts[slot] != 0) return 0;
    }
    return 1;
}
