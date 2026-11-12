#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 998'244'353;
constexpr std::size_t max_length = 210;
struct Record { std::int64_t priority, a, b; };
}

extern "C" std::int64_t point_set_range_sort_range_composite(const std::int64_t* input, std::size_t length)
{
    if (input == nullptr || length < 2 || length > max_length) return -1;
    if (input[0] < 1 || input[0] > 16 || input[1] < 1 || input[1] > 32) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto q = static_cast<std::size_t>(input[1]);
    if (length < 2 + 3 * n) return -1;
    std::array<Record, 16> records{};
    std::array<std::int64_t, 48> seen{};
    std::size_t seen_count = 0, cursor = 2;
    for (std::size_t i = 0; i < n; ++i) {
        const auto p = input[cursor++], a = input[cursor++], b = input[cursor++];
        if (p < 0 || p > 1'000'000'000 || a < 1 || a >= modulus || b < 0 || b >= modulus) return -1;
        for (std::size_t j = 0; j < seen_count; ++j) if (seen[j] == p) return -1;
        seen[seen_count++] = p;
        records[i] = {p, a, b};
    }
    std::int64_t checksum = 0, query_number = 0;
    for (std::size_t operation = 0; operation < q; ++operation) {
        if (cursor >= length) return -1;
        const auto opcode = input[cursor++];
        if (opcode == 0) {
            if (length - cursor < 4) return -1;
            const auto index = input[cursor++], p = input[cursor++], a = input[cursor++], b = input[cursor++];
            if (index < 0 || index >= static_cast<std::int64_t>(n) || p < 0 || p > 1'000'000'000 || a < 1 || a >= modulus || b < 0 || b >= modulus) return -1;
            for (std::size_t j = 0; j < seen_count; ++j) if (seen[j] == p) return -1;
            seen[seen_count++] = p;
            records[static_cast<std::size_t>(index)] = {p, a, b};
        } else if (opcode == 1) {
            if (length - cursor < 3) return -1;
            const auto left = input[cursor++], right = input[cursor++], x = input[cursor++];
            if (left < 0 || left >= right || right > static_cast<std::int64_t>(n) || x < 0 || x >= modulus) return -1;
            auto answer = x;
            for (auto i = static_cast<std::size_t>(left); i < static_cast<std::size_t>(right); ++i)
                answer = (records[i].a * answer + records[i].b) % modulus;
            ++query_number;
            checksum = (checksum + query_number * answer) % modulus;
        } else if (opcode == 2 || opcode == 3) {
            if (length - cursor < 2) return -1;
            const auto left = input[cursor++], right = input[cursor++];
            if (left < 0 || left >= right || right > static_cast<std::int64_t>(n)) return -1;
            for (std::size_t i = static_cast<std::size_t>(left) + 1; i < static_cast<std::size_t>(right); ++i) {
                const auto item = records[i];
                auto j = i;
                while (j > static_cast<std::size_t>(left) &&
                       (opcode == 2 ? records[j - 1].priority > item.priority : records[j - 1].priority < item.priority)) {
                    records[j] = records[j - 1];
                    --j;
                }
                records[j] = item;
            }
        } else return -1;
    }
    return cursor == length ? checksum : -1;
}
