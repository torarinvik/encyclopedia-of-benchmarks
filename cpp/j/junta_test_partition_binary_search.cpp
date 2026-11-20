#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 8;
constexpr std::size_t rounds = 24;
constexpr std::size_t max_groups = 8;
constexpr std::size_t max_words = 7;

int function_value(const std::array<std::uint64_t, 4>& truth, std::uint32_t point) {
    return static_cast<int>((truth[point / 64] >> (point % 64)) & 1U);
}

void put_i64(std::uint8_t* out, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        out[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t junta_test_partition_binary_search(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) {
    if (input == nullptr || length < 3 || length > 40) return -1;
    const auto n_value = input[0];
    const auto group_value = input[1];
    const auto words_value = input[2];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n)
        || group_value < 1 || group_value > n_value) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto group_count = static_cast<std::size_t>(group_value);
    const auto domain = std::size_t{1} << n;
    const auto truth_words = (domain + 63) / 64;
    if (words_value != static_cast<std::int64_t>(truth_words)) return -1;
    const auto table_at = std::size_t{3};
    const auto labels_at = table_at + truth_words;
    const auto tape_at = labels_at + n;
    if (length != tape_at + rounds) return -1;

    std::array<std::uint64_t, 4> truth{};
    for (std::size_t word = 0; word < truth_words; ++word)
        truth[word] = static_cast<std::uint64_t>(input[table_at + word]);
    const auto tail = domain % 64;
    if (tail != 0 && (truth[truth_words - 1] >> tail) != 0) return -1;

    std::array<std::uint32_t, max_groups> group_masks{};
    std::uint32_t seen_groups = 0;
    for (std::size_t coordinate = 0; coordinate < n; ++coordinate) {
        const auto group = input[labels_at + coordinate];
        if (group < 0 || group >= group_value) return -1;
        group_masks[static_cast<std::size_t>(group)] |= std::uint32_t{1} << coordinate;
        seen_groups |= std::uint32_t{1} << static_cast<unsigned>(group);
    }
    if (seen_groups != ((std::uint32_t{1} << group_count) - 1)) return -1;
    const auto pair_limit = std::uint64_t{1} << (2 * n);
    for (std::size_t round = 0; round < rounds; ++round) {
        const auto packed = input[tape_at + round];
        if (packed < 0 || static_cast<std::uint64_t>(packed) >= pair_limit) return -1;
    }

    std::array<std::int64_t, max_words> result{};
    std::array<std::int64_t, 2> found_round{};
    std::array<std::int64_t, 2> found_group{};
    std::size_t found = 0;
    std::size_t queries = 0;
    const auto all_coordinates = (std::uint32_t{1} << n) - 1;
    auto active = all_coordinates;

    for (std::size_t round = 0; round < rounds; ++round) {
        const auto packed = static_cast<std::uint64_t>(input[tape_at + round]);
        const auto x = static_cast<std::uint32_t>(packed & all_coordinates);
        const auto y = static_cast<std::uint32_t>((packed >> n) & all_coordinates);
        const auto hybrid = (x & ~active) | (y & active);
        const auto left_value = function_value(truth, x);
        const auto right_value = function_value(truth, hybrid);
        queries += 2;
        if (left_value == right_value) continue;

        std::array<std::uint8_t, max_groups> candidates{};
        std::size_t candidate_count = 0;
        for (std::size_t group = 0; group < group_count; ++group)
            if ((group_masks[group] & active) != 0)
                candidates[candidate_count++] = static_cast<std::uint8_t>(group);
        auto left_endpoint = x;
        auto right_endpoint = hybrid;
        auto endpoint_value = left_value;
        while (candidate_count > 1) {
            const auto cut = candidate_count / 2;
            std::uint32_t low_mask = 0;
            for (std::size_t i = 0; i < cut; ++i) low_mask |= group_masks[candidates[i]];
            const auto probe = (left_endpoint & ~low_mask) | (right_endpoint & low_mask);
            const auto probe_value = function_value(truth, probe);
            ++queries;
            if (probe_value != endpoint_value) {
                right_endpoint = probe;
                candidate_count = cut;
            } else {
                left_endpoint = probe;
                endpoint_value = probe_value;
                for (std::size_t i = cut; i < candidate_count; ++i)
                    candidates[i - cut] = candidates[i];
                candidate_count -= cut;
            }
        }
        const auto selected = candidates[0];
        active &= ~group_masks[selected];
        found_round[found] = static_cast<std::int64_t>(round);
        found_group[found] = selected;
        ++found;
        if (found > 1) break;
    }

    result[0] = found > 1 ? 1 : 0;
    result[1] = static_cast<std::int64_t>(found);
    result[2] = static_cast<std::int64_t>(queries);
    for (std::size_t i = 0; i < found; ++i) {
        result[3 + 2 * i] = found_round[i];
        result[4 + 2 * i] = found_group[i];
    }
    const auto result_words = 3 + 2 * found;
    const auto result_bytes = result_words * 8;
    if (output == nullptr || capacity < result_bytes) return -2;
    for (std::size_t i = 0; i < result_words; ++i) put_i64(output, i * 8, result[i]);
    return static_cast<std::int64_t>(result_bytes);
}
