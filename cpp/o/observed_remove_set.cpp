#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxOperations = 32;
constexpr std::size_t kMaxTags = 2 * kMaxOperations;
constexpr std::size_t kMaxInput = 1 + 4 * kMaxOperations;
}

extern "C" std::int64_t observed_remove_set(const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > kMaxInput) return -1;
    const std::int64_t q_value = input[0];
    if (q_value < 0 || q_value > static_cast<std::int64_t>(kMaxOperations) ||
        length != 1 + static_cast<std::size_t>(q_value) * 4) return -1;
    const std::size_t q = static_cast<std::size_t>(q_value);
    for (std::size_t i = 0; i < q; ++i) {
        const auto op = input[1 + i * 4], replica = input[2 + i * 4];
        const auto element = input[3 + i * 4], peer = input[4 + i * 4];
        if (op >= 0 && op <= 2) {
            if (replica < 0 || replica > 1 || element < 0 || element > 15 || peer != 0) return -1;
        } else if (op == 3 || op == 4) {
            if (replica < 0 || replica > 1 || element != 0 || peer < 0 || peer > 1) return -1;
        } else return -1;
    }

    bool used[kMaxTags]{};
    std::int64_t tag_element[kMaxTags]{};
    std::size_t next_sequence[2]{};
    bool additions[2][kMaxTags]{};
    bool removals[2][kMaxTags]{};
    std::int64_t answer = 0;
    std::size_t read_count = 0;
    for (std::size_t i = 0; i < q; ++i) {
        const auto op = input[1 + i * 4];
        const auto replica = static_cast<std::size_t>(input[2 + i * 4]);
        const auto element = input[3 + i * 4];
        const auto peer = static_cast<std::size_t>(input[4 + i * 4]);
        bool result = false;
        if (op == 0) {
            const std::size_t tag = replica * kMaxOperations + next_sequence[replica]++;
            used[tag] = true;
            tag_element[tag] = element;
            additions[replica][tag] = true;
        } else if (op == 1) {
            for (std::size_t tag = 0; tag < kMaxTags; ++tag)
                if (additions[replica][tag] && !removals[replica][tag] && used[tag] && tag_element[tag] == element)
                    removals[replica][tag] = true;
        } else if (op == 2) {
            for (std::size_t tag = 0; tag < kMaxTags; ++tag)
                if (additions[replica][tag] && !removals[replica][tag] && used[tag] && tag_element[tag] == element)
                    result = true;
        } else if (op == 3) {
            for (std::size_t tag = 0; tag < kMaxTags; ++tag) {
                additions[replica][tag] = additions[replica][tag] || additions[peer][tag];
                removals[replica][tag] = removals[replica][tag] || removals[peer][tag];
            }
        } else {
            result = true;
            for (std::size_t tag = 0; tag < kMaxTags; ++tag)
                if ((additions[replica][tag] && !additions[peer][tag]) ||
                    (removals[replica][tag] && !removals[peer][tag])) result = false;
        }
        if (op == 2 || op == 4) {
            if (result) answer |= std::int64_t{1} << read_count;
            ++read_count;
        }
    }
    return answer;
}
