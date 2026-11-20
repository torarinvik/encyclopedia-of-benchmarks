// Clean-room bounded greedy LZ-End phrase parser.
module lz_end_phrase_parsing;

fn long lz_end_phrase_parsing(long* input, usz length) @export("lz_end_phrase_parsing") {
    if (input == null || length < 1 || length > 66) return -1;
    if (input[0] < 0 || input[0] > 64 || length != (usz)input[0] + 1) return -1;
    int n = (int)input[0];
    for (int i = 0; i < n; i++) if (input[i + 1] < 0 || input[i + 1] > 255) return -1;

    int[64] boundaries = {};
    int[64] phrase_lengths = {};
    int phrases = 0, position = 0;
    while (position < n) {
        int best_copy = 0;
        for (int copy_length = n - position - 1; copy_length > 0 && best_copy == 0; copy_length--) {
            for (int prior = phrases - 1; prior >= 0 && best_copy == 0; prior--) {
                int boundary = boundaries[prior];
                if (boundary < copy_length) continue;
                bool matches = true;
                for (int offset = 0; offset < copy_length; offset++) {
                    if (input[1 + position + offset] != input[1 + boundary - copy_length + offset]) { matches = false; break; }
                }
                if (matches) best_copy = copy_length;
            }
        }
        phrase_lengths[phrases] = best_copy + 1;
        position += phrase_lengths[phrases];
        boundaries[phrases] = position;
        phrases++;
    }
    long checksum = 0;
    for (int i = 0; i < phrases; i++) checksum += (long)(i + 1) * phrase_lengths[i];
    return 133121 * phrases + checksum;
}
