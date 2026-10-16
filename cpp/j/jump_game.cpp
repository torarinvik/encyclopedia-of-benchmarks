#include <cstddef>
#include <cstdint>

extern "C" int64_t jump_game(const int64_t *input, size_t length) {
    if (input == nullptr || length < 2 || length > 1025 || input[0] < 1 || input[0] > 1024 || length != static_cast<size_t>(input[0]) + 1) return -2;
    const size_t n = static_cast<size_t>(input[0]);
    for (size_t i = 0; i < n; ++i) if (input[i + 1] < 0 || input[i + 1] > 1000000) return -2;
    size_t last_pos = n - 1;
    for (size_t i = n; i-- > 0;) {
        if (i + static_cast<size_t>(input[i + 1]) >= last_pos) last_pos = i;
    }
    return last_pos == 0 ? 1 : 0;
}
