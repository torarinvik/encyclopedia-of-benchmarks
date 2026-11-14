// Uncompiled and unexecuted batched subsequence-automaton draft.
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t subsequence_automaton(const std::int64_t* input,
                                              std::size_t length) {
    if (!input || length < 2 || length > 354) return -1;
    if (input[0] < 0 || input[0] > 64 || input[1] < 0 || input[1] > 32) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto q = static_cast<std::size_t>(input[1]);
    if (length < 2 + n) return -1;
    for (std::size_t i = 0; i < n; ++i)
        if (input[2+i] < 0 || input[2+i] > 3) return -1;
    std::array<std::array<std::size_t, 4>, 65> next{};
    next[n].fill(n);
    for (std::size_t i = n; i-- > 0;) {
        next[i] = next[i+1];
        next[i][static_cast<std::size_t>(input[2+i])] = i;
    }
    std::size_t position = 2+n, total = 0;
    std::int64_t answer = 0;
    for (std::size_t query = 0; query < q; ++query) {
        if (position == length || input[position] < 0 || input[position] > 256) return -1;
        const auto size = static_cast<std::size_t>(input[position++]);
        if (size > 256-total || size > length-position) return -1;
        std::size_t cursor = 0;
        bool match = true;
        for (std::size_t i = 0; i < size; ++i) {
            const auto value = input[position+i];
            if (value < 0 || value > 3) return -1;
            if (match) {
                const auto found = next[cursor][static_cast<std::size_t>(value)];
                if (found == n) match = false;
                else cursor = found+1;
            }
        }
        if (match) answer += static_cast<std::int64_t>(query+1);
        position += size;
        total += size;
    }
    return position == length ? answer : -1;
}
