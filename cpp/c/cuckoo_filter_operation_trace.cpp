#include <array>
#include <cstddef>
#include <cstdint>
#include <initializer_list>

namespace {
constexpr std::size_t bucket_count = 8;
constexpr std::size_t bucket_width = 4;
constexpr std::size_t operation_limit = 32;
constexpr std::size_t kick_limit = 8;
using Table = std::array<std::array<std::int64_t, bucket_width>, bucket_count>;

std::size_t delta(std::int64_t fingerprint) {
    return 1 + ((5 * static_cast<std::size_t>(fingerprint) + 3) % 7);
}

std::size_t vacant(const Table &table, std::size_t bucket) {
    for (std::size_t offset = 0; offset < bucket_width; ++offset)
        if (table[bucket][offset] == 0) return offset;
    return bucket_width;
}

bool insert(Table &table, std::size_t primary, std::int64_t fingerprint) {
    const auto alternate = primary ^ delta(fingerprint);
    auto offset = vacant(table, primary);
    if (offset < bucket_width) { table[primary][offset] = fingerprint; return true; }
    offset = vacant(table, alternate);
    if (offset < bucket_width) { table[alternate][offset] = fingerprint; return true; }

    auto current = primary;
    auto carry = fingerprint;
    for (std::size_t step = 0; step < kick_limit; ++step) {
        const auto old = table[current][0];
        table[current][0] = carry;
        carry = old;
        current ^= delta(carry);
        offset = vacant(table, current);
        if (offset < bucket_width) { table[current][offset] = carry; return true; }
    }
    return false;
}

void write_i64(std::uint8_t *output, std::size_t index, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[index * 8 + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t cuckoo_filter_operation_trace(
        const std::int64_t *input, std::size_t length,
        std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 4 || length > 98) return -1;
    const auto raw_count = input[0];
    if (raw_count < 1 || raw_count > static_cast<std::int64_t>(operation_limit)) return -1;
    const auto count = static_cast<std::size_t>(raw_count);
    if (length != 1 + 3 * count) return -1;
    for (std::size_t i = 0; i < count; ++i) {
        const auto op = input[1 + 3 * i];
        const auto home = input[2 + 3 * i];
        const auto fingerprint = input[3 + 3 * i];
        if (op < 0 || op > 2 || home < 0 || home >= static_cast<std::int64_t>(bucket_count) ||
                fingerprint < 1 || fingerprint > 15) return -1;
    }
    const auto required = count * 8;
    if (output == nullptr || capacity < required) return -2;

    Table table{};
    std::array<std::int64_t, operation_limit> answers{};
    for (std::size_t i = 0; i < count; ++i) {
        const auto op = input[1 + 3 * i];
        const auto home = static_cast<std::size_t>(input[2 + 3 * i]);
        const auto fingerprint = input[3 + 3 * i];
        const auto peer = home ^ delta(fingerprint);
        if (op == 0) {
            if (!insert(table, home, fingerprint)) return -3;
            answers[i] = 1;
        } else if (op == 1) {
            bool found = false;
            for (const auto bucket : {home, peer})
                for (const auto value : table[bucket]) if (value == fingerprint) found = true;
            answers[i] = found ? 1 : 0;
        } else {
            bool removed = false;
            for (const auto bucket : {home, peer}) {
                for (auto &value : table[bucket]) {
                    if (value == fingerprint) { value = 0; removed = true; break; }
                }
                if (removed) break;
            }
            answers[i] = removed ? 1 : 0;
        }
    }
    for (std::size_t i = 0; i < count; ++i) write_i64(output, i, answers[i]);
    return static_cast<std::int64_t>(required);
}
