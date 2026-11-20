#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 6;
constexpr std::size_t max_assignments = 3;
constexpr std::size_t max_input = 27;
constexpr std::size_t max_words = 73;

void put_i64(std::uint8_t *output, std::size_t word, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[8 * word + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t all_distances_sketch_k_mins(
        const std::int64_t *input, std::size_t length,
        std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > max_input) return -1;
    const auto n0 = input[0], assignments0 = input[1];
    if (n0 < 1 || n0 > static_cast<std::int64_t>(max_n)
            || assignments0 < 1 || assignments0 > static_cast<std::int64_t>(max_assignments)) return -1;
    const auto n = static_cast<std::size_t>(n0);
    const auto assignments = static_cast<std::size_t>(assignments0);
    if (length != 2 + n + assignments * n) return -1;

    std::int64_t distances[max_n]{};
    for (std::size_t item = 0; item < n; ++item) {
        const auto distance = input[2 + item];
        if (distance < 0 || distance > 1000000
                || (item != 0 && distances[item - 1] >= distance)) return -1;
        distances[item] = distance;
    }

    std::int64_t ranks[max_assignments][max_n]{};
    for (std::size_t assignment = 0; assignment < assignments; ++assignment) {
        bool seen[max_n]{};
        for (std::size_t item = 0; item < n; ++item) {
            const auto rank = input[2 + n + assignment * n + item];
            if (rank < 0 || rank >= n0 || seen[static_cast<std::size_t>(rank)]) return -1;
            seen[static_cast<std::size_t>(rank)] = true;
            ranks[assignment][item] = rank;
        }
    }

    std::int64_t staged[max_words]{};
    std::size_t count = 0;
    for (std::size_t assignment = 0; assignment < assignments; ++assignment) {
        auto best_rank = n0;
        for (std::size_t item = 0; item < n; ++item) {
            const auto rank = ranks[assignment][item];
            if (rank < best_rank) {
                staged[1 + 4 * count] = static_cast<std::int64_t>(assignment);
                staged[2 + 4 * count] = static_cast<std::int64_t>(item);
                staged[3 + 4 * count] = rank;
                staged[4 + 4 * count] = distances[item];
                ++count;
                best_rank = rank;
            }
        }
    }
    staged[0] = static_cast<std::int64_t>(count);
    const auto words = 1 + 4 * count;
    const auto bytes = 8 * words;
    if (output == nullptr || capacity < bytes) return -2;
    for (std::size_t word = 0; word < words; ++word) put_i64(output, word, staged[word]);
    return static_cast<std::int64_t>(bytes);
}
