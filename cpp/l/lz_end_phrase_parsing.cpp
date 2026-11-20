// Clean-room bounded greedy LZ-End phrase parser.
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t lz_end_phrase_parsing(const std::int64_t* input, std::size_t length) {
    if (!input || length < 1 || length > 66 || input[0] < 0 || input[0] > 64 ||
        length != static_cast<std::size_t>(input[0]) + 1) return -1;
    const int n = static_cast<int>(input[0]);
    for (int i = 0; i < n; ++i) if (input[i + 1] < 0 || input[i + 1] > 255) return -1;

    std::array<int, 64> boundaries{};
    std::array<int, 64> phrase_lengths{};
    int phrases = 0, position = 0;
    while (position < n) {
        const int maximum_copy = n - position - 1;
        int best_copy = 0;
        for (int copy_length = maximum_copy; copy_length > 0 && best_copy == 0; --copy_length) {
            for (int prior = phrases - 1; prior >= 0 && best_copy == 0; --prior) {
                const int boundary = boundaries[prior];
                if (boundary < copy_length) continue;
                bool matches = true;
                for (int offset = 0; offset < copy_length; ++offset) {
                    if (input[1 + position + offset] != input[1 + boundary - copy_length + offset]) { matches = false; break; }
                }
                if (matches) best_copy = copy_length;
            }
        }
        phrase_lengths[phrases] = best_copy + 1;
        position += phrase_lengths[phrases];
        boundaries[phrases] = position;
        ++phrases;
    }
    std::int64_t checksum = 0;
    for (int i = 0; i < phrases; ++i) checksum += static_cast<std::int64_t>(i + 1) * phrase_lengths[i];
    return static_cast<std::int64_t>(133121) * phrases + checksum;
}
