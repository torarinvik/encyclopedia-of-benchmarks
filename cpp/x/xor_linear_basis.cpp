#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxOperations = 64;
constexpr std::size_t kMaxInsertions = 16;
constexpr std::size_t kMaxInputValues = 1 + 2 * kMaxOperations;
constexpr std::size_t kBitCount = 63;

void insert_value(std::array<std::uint64_t, kBitCount> &basis, std::uint64_t value) {
    for (int bit = static_cast<int>(kBitCount) - 1; bit >= 0 && value != 0; --bit) {
        if (((value >> bit) & 1) == 0) continue;
        if (basis[static_cast<std::size_t>(bit)] == 0) {
            basis[static_cast<std::size_t>(bit)] = value;
            return;
        }
        value ^= basis[static_cast<std::size_t>(bit)];
    }
}

std::uint64_t maximum_value(const std::array<std::uint64_t, kBitCount> &basis) {
    std::uint64_t best = 0;
    for (int bit = static_cast<int>(kBitCount) - 1; bit >= 0; --bit) {
        const auto candidate = best ^ basis[static_cast<std::size_t>(bit)];
        if (candidate > best) best = candidate;
    }
    return best;
}

bool contains_value(const std::array<std::uint64_t, kBitCount> &basis,
                    std::uint64_t value) {
    for (int bit = static_cast<int>(kBitCount) - 1; bit >= 0; --bit) {
        if (((value >> bit) & 1) == 0) continue;
        const auto pivot = basis[static_cast<std::size_t>(bit)];
        if (pivot == 0) return false;
        value ^= pivot;
    }
    return value == 0;
}

void store_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t xor_linear_basis(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > kMaxInputValues) return -1;
    const auto operation_count_value = input[0];
    if (operation_count_value < 1 || operation_count_value > static_cast<std::int64_t>(kMaxOperations)) return -1;
    const auto operation_count = static_cast<std::size_t>(operation_count_value);

    std::array<std::uint64_t, kBitCount> basis{};
    std::array<std::int64_t, kMaxOperations> results{};
    std::size_t result_count = 0, cursor = 1, insertion_count = 0;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        if (cursor >= length) return -1;
        const auto kind = input[cursor++];
        if (kind == 0 || kind == 2) {
            if (cursor >= length) return -1;
            const auto raw_value = input[cursor++];
            if (raw_value < 0) return -1;
            const auto value = static_cast<std::uint64_t>(raw_value);
            if (kind == 0) {
                if (++insertion_count > kMaxInsertions) return -1;
                insert_value(basis, value);
            } else {
                results[result_count++] = contains_value(basis, value) ? 1 : 0;
            }
        } else if (kind == 1) {
            results[result_count++] = static_cast<std::int64_t>(maximum_value(basis));
        } else {
            return -1;
        }
    }
    if (cursor != length) return -1;

    const auto output_bytes = result_count * 8;
    if (output_bytes == 0) return 0;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t result = 0; result < result_count; ++result)
        store_le(output, result * 8, results[result]);
    return static_cast<std::int64_t>(output_bytes);
}
