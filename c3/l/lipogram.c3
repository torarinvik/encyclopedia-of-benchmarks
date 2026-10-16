module lipogram;

fn long lipogram(long* input, usz length) @export("lipogram") {
    if (input == null || length < 2 || length > 1026 || input[0] < 0 || input[0] > 1024 || length != (usz)input[0] + 2) return -1;
    usz n = (usz)input[0];
    long expected = input[length - 1];
    if (expected < 0 || expected > 67108863) return -1;
    long seen = 0;
    for (usz i = 0; i < n; i++) {
        long ch = input[i + 1];
        if (ch >= 'A' && ch <= 'Z') ch += 'a' - 'A';
        if (ch >= 'a' && ch <= 'z') {
            seen |= 1L << (ch - 'a');
        } else if (ch != 9 && ch != 10 && ch != 11 && ch != 12 && ch != 13 && ch != 32) {
            return -1;
        }
    }
    long missing = ((1L << 26) - 1) & ~seen;
    return missing == expected ? 1 : 0;
}
