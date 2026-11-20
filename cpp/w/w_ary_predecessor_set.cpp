/* 64-ary hierarchical bitmap predecessor set. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t universe = 262144;

unsigned low_bit(std::uint64_t bits) noexcept {
    unsigned low = 0, high = 64;
    while (high - low > 1) {
        const unsigned middle = (low + high) / 2;
        const auto mask = (std::uint64_t{1} << middle) - 1;
        if ((bits & mask) != 0) high = middle; else low = middle;
    }
    return low;
}

unsigned high_bit(std::uint64_t bits) noexcept {
    unsigned low = 0, high = 64;
    while (high - low > 1) {
        const unsigned middle = (low + high) / 2;
        if ((bits >> middle) != 0) low = middle; else high = middle;
    }
    return low;
}

std::int64_t insert_key(std::array<std::uint64_t, 4096>& leaf,
                        std::array<std::uint64_t, 64>& group,
                        std::uint64_t& top, std::uint32_t key) noexcept {
    const auto word = key >> 6, bit_index = key & 63;
    const auto bit = std::uint64_t{1} << bit_index;
    const auto old = leaf[word];
    if ((old & bit) != 0) return 0;
    if (old == 0) {
        const auto g = word >> 6, slot = word & 63;
        if (group[g] == 0) top |= std::uint64_t{1} << g;
        group[g] |= std::uint64_t{1} << slot;
    }
    leaf[word] = old | bit;
    return 1;
}

std::int64_t erase_key(std::array<std::uint64_t, 4096>& leaf,
                       std::array<std::uint64_t, 64>& group,
                       std::uint64_t& top, std::uint32_t key) noexcept {
    const auto word = key >> 6, bit_index = key & 63;
    const auto bit = std::uint64_t{1} << bit_index;
    const auto old = leaf[word];
    if ((old & bit) == 0) return 0;
    leaf[word] = old & ~bit;
    if (leaf[word] == 0) {
        const auto g = word >> 6, slot = word & 63;
        group[g] &= ~(std::uint64_t{1} << slot);
        if (group[g] == 0) top &= ~(std::uint64_t{1} << g);
    }
    return 1;
}

std::int64_t successor(const std::array<std::uint64_t, 4096>& leaf,
                       const std::array<std::uint64_t, 64>& group,
                       std::uint64_t top, std::uint32_t key) noexcept {
    const auto word = key >> 6, bit_index = key & 63;
    const auto candidates = leaf[word] & (~std::uint64_t{0} << bit_index);
    if (candidates != 0) return static_cast<std::int64_t>(word * 64 + low_bit(candidates) + 1);
    const auto g = word >> 6, slot = word & 63;
    auto later = slot == 63 ? std::uint64_t{0} : group[g] >> (slot + 1);
    std::uint32_t next_word;
    if (later != 0) next_word = g * 64 + slot + 1 + low_bit(later);
    else {
        later = g == 63 ? std::uint64_t{0} : top >> (g + 1);
        if (later == 0) return 0;
        const auto next_group = g + 1 + low_bit(later);
        next_word = next_group * 64 + low_bit(group[next_group]);
    }
    return static_cast<std::int64_t>(next_word * 64 + low_bit(leaf[next_word]) + 1);
}

std::int64_t predecessor(const std::array<std::uint64_t, 4096>& leaf,
                         const std::array<std::uint64_t, 64>& group,
                         std::uint64_t top, std::uint32_t key) noexcept {
    const auto word = key >> 6, bit_index = key & 63;
    const auto candidates = leaf[word] & ((std::uint64_t{1} << bit_index) - 1);
    if (candidates != 0) return static_cast<std::int64_t>(word * 64 + high_bit(candidates) + 1);
    const auto g = word >> 6, slot = word & 63;
    auto earlier = group[g] & ((std::uint64_t{1} << slot) - 1);
    std::uint32_t previous_word;
    if (earlier != 0) previous_word = g * 64 + high_bit(earlier);
    else {
        earlier = top & ((std::uint64_t{1} << g) - 1);
        if (earlier == 0) return 0;
        const auto previous_group = high_bit(earlier);
        previous_word = previous_group * 64 + high_bit(group[previous_group]);
    }
    return static_cast<std::int64_t>(previous_word * 64 + high_bit(leaf[previous_word]) + 1);
}
} // namespace

extern "C" std::int64_t w_ary_predecessor_set(const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > 66) return -1;
    if (input[0] < 0 || input[0] > 32) return -1;
    const auto q = static_cast<std::size_t>(input[0]);
    if (length != 1 + 2 * q) return -1;
    std::array<std::uint64_t, 4096> leaf{};
    std::array<std::uint64_t, 64> group{};
    std::uint64_t top = 0;
    std::int64_t result = 0;
    std::size_t cursor = 1;
    for (std::size_t i = 0; i < q; ++i) {
        const auto opcode = input[cursor], raw_key = input[cursor + 1];
        cursor += 2;
        if (opcode < 0 || opcode > 4 || raw_key < 0 || raw_key >= universe) return -1;
        const auto key = static_cast<std::uint32_t>(raw_key);
        std::int64_t answer;
        if (opcode == 0) answer = insert_key(leaf, group, top, key);
        else if (opcode == 1) answer = erase_key(leaf, group, top, key);
        else if (opcode == 2) answer = (leaf[key >> 6] & (std::uint64_t{1} << (key & 63))) != 0;
        else if (opcode == 3) answer = successor(leaf, group, top, key);
        else answer = predecessor(leaf, group, top, key);
        result += static_cast<std::int64_t>(i + 1) * answer;
    }
    return result;
}
