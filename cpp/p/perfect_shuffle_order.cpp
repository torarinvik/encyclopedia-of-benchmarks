#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_deck_size = 10000;
constexpr std::size_t max_parseable_length = 2;
}

extern "C" std::int64_t perfect_shuffle_order(const std::int64_t *input,
                                               std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_parseable_length || length != 1) return -1;
    const std::int64_t deck_word = input[0];
    if (deck_word < 2 || deck_word > static_cast<std::int64_t>(max_deck_size)
        || (deck_word & 1) != 0) return -1;
    const auto deck_size = static_cast<std::size_t>(deck_word);
    const auto half = deck_size / 2;

    std::array<std::int64_t, max_deck_size> first{};
    std::array<std::int64_t, max_deck_size> second{};
    auto *current = first.data();
    auto *next = second.data();
    for (std::size_t i = 0; i < deck_size; ++i) current[i] = static_cast<std::int64_t>(i);

    std::int64_t count = 0;
    for (;;) {
        for (std::size_t i = 0; i < half; ++i) {
            next[2 * i] = current[i];
            next[2 * i + 1] = current[half + i];
        }
        ++count;
        std::size_t i = 0;
        while (i < deck_size && next[i] == static_cast<std::int64_t>(i)) ++i;
        if (i == deck_size) return count;
        auto *temporary = current;
        current = next;
        next = temporary;
    }
}
