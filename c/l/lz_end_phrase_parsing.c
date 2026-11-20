/* Clean-room bounded greedy LZ-End phrase parser. */
#include <stddef.h>
#include <stdint.h>

int64_t lz_end_phrase_parsing(const int64_t *input, size_t length) {
    if (!input || length < 1 || length > 66) return -1;
    if (input[0] < 0 || input[0] > 64 || length != (size_t)input[0] + 1) return -1;
    const int n = (int)input[0];
    for (int i = 0; i < n; ++i) if (input[i + 1] < 0 || input[i + 1] > 255) return -1;

    int boundaries[64] = {0};
    int phrase_lengths[64] = {0};
    int phrases = 0, position = 0;
    while (position < n) {
        const int remaining = n - position;
        const int maximum_copy = remaining - 1;
        int best_copy = 0;
        for (int copy_length = maximum_copy; copy_length > 0 && best_copy == 0; --copy_length) {
            for (int prior = phrases - 1; prior >= 0 && best_copy == 0; --prior) {
                const int boundary = boundaries[prior];
                if (boundary < copy_length) continue;
                int matches = 1;
                for (int offset = 0; offset < copy_length; ++offset) {
                    if (input[1 + position + offset] != input[1 + boundary - copy_length + offset]) { matches = 0; break; }
                }
                if (matches) best_copy = copy_length;
            }
        }
        const int phrase_length = best_copy + 1;
        phrase_lengths[phrases] = phrase_length;
        position += phrase_length;
        boundaries[phrases] = position;
        ++phrases;
    }
    int64_t checksum = 0;
    for (int i = 0; i < phrases; ++i) checksum += (int64_t)(i + 1) * phrase_lengths[i];
    return (int64_t)133121 * phrases + checksum;
}
