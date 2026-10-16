#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_candidates = 8;
constexpr std::int64_t max_target = 20;
constexpr std::size_t max_packed_words = 4096;

struct Search {
    const std::int64_t *candidates;
    std::size_t count;
    std::int64_t path[max_target];
    std::int64_t packed[max_packed_words];
    std::size_t used;
};

void enumerate(Search &search, std::size_t start, std::int64_t remaining, std::size_t depth) {
    if (remaining == 0) {
        search.packed[search.used++] = static_cast<std::int64_t>(depth);
        for (std::size_t i = 0; i < depth; ++i) search.packed[search.used++] = search.path[i];
        ++search.packed[0];
        return;
    }
    for (std::size_t i = start; i < search.count; ++i) {
        const auto candidate = search.candidates[i];
        if (candidate > remaining) break;
        search.path[depth] = candidate;
        enumerate(search, i, remaining - candidate, depth + 1);
    }
}

void put_i64(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t combination_sum(const std::int64_t *input, std::size_t length,
                                          std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 3) return -1;
    const auto count_value = input[0], target = input[1];
    if (count_value < 1 || count_value > static_cast<std::int64_t>(max_candidates) ||
        target < 0 || target > max_target) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != count + 2) return -1;
    for (std::size_t i = 0; i < count; ++i) {
        const auto candidate = input[i + 2];
        if (candidate < 1 || candidate > 24 || (i > 0 && input[i + 1] >= candidate)) return -1;
    }

    Search search{input + 2, count, {}, {}, 1};
    search.packed[0] = 0;
    enumerate(search, 0, target, 0);
    const auto required = search.used * 8;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t i = 0; i < search.used; ++i) put_i64(output, i * 8, search.packed[i]);
    return static_cast<std::int64_t>(required);
}
