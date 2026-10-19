#include <cstddef>
#include <cstdint>
#include <cstdlib>

namespace {
constexpr std::int64_t max_array_size = 100000;
constexpr std::int64_t max_rounds = 8;
constexpr std::int64_t max_scans_per_array = 64;

std::uint32_t puzzle_rand(std::uint64_t& state) {
    state = state * UINT64_C(1103515245) + UINT64_C(12345);
    const std::uint32_t shifted = static_cast<std::uint32_t>(state / UINT64_C(65536));
    return shifted % UINT32_C(32767) + UINT32_C(1);
}

std::size_t puzzle_rand_int(std::size_t minimum, std::size_t maximum, std::uint64_t& state) {
    const std::size_t range = maximum - minimum + 1;
    const auto draw = puzzle_rand(state);
    const auto offset = static_cast<std::size_t>(static_cast<double>(range) *
                                                  (static_cast<double>(draw) / 32768.0));
    return offset == range ? offset + minimum - 1 : offset + minimum;
}

void puzzle_shuffle(std::int32_t* items, std::size_t length, std::uint64_t& state) {
    for (std::size_t index = length - 1; index > 0; --index) {
        const std::size_t range = index + 1;
        const auto draw = puzzle_rand(state);
        const auto k = static_cast<std::size_t>(static_cast<double>(range) *
                                                (static_cast<double>(draw) / 32768.0));
        const std::size_t chosen = k == range ? k - 1 : k;
        const auto temporary = items[index];
        items[index] = items[chosen];
        items[chosen] = temporary;
    }
}

std::int32_t puzzle_find_duplicate(const std::int32_t* data, std::size_t length) {
    std::uint32_t result = 0;
    for (std::size_t index = 0; index < length; ++index)
        result ^= static_cast<std::uint32_t>(index + 1) ^ static_cast<std::uint32_t>(data[index]);
    result ^= static_cast<std::uint32_t>(length);
    return static_cast<std::int32_t>(result);
}

void puzzle_store_i32_le(std::uint8_t* output, std::size_t offset, std::int32_t value) {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
} // namespace

extern "C" std::int64_t benchmarkgame_puzzle(const std::int64_t* input, std::size_t length,
                                              std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length != 3) return -1;
    const auto raw_size = input[0], raw_rounds = input[1], raw_scans = input[2];
    if (raw_size < 1 || raw_size > max_array_size || raw_rounds < 1 || raw_rounds > max_rounds ||
        raw_scans < 1 || raw_scans > max_scans_per_array) return -1;
    const auto size = static_cast<std::size_t>(raw_size);
    const auto rounds = static_cast<std::size_t>(raw_rounds);
    const auto scans = static_cast<std::size_t>(raw_scans);
    const auto output_bytes = rounds * 4;
    if (output_capacity < output_bytes || output == nullptr) return -2;

    std::uint64_t random_state = 1;
    for (std::size_t round = 0; round < rounds; ++round) {
        auto* data = static_cast<std::int32_t*>(std::malloc((size + 1) * sizeof(*data)));
        if (data == nullptr) return -1;
        for (std::size_t index = 0; index <= size; ++index) data[index] = static_cast<std::int32_t>(index);
        data[0] = static_cast<std::int32_t>(puzzle_rand_int(1, size, random_state));
        puzzle_shuffle(data, size + 1, random_state);
        std::int32_t duplicate = 0;
        for (std::size_t scan = 0; scan < scans; ++scan)
            duplicate = puzzle_find_duplicate(data, size + 1);
        puzzle_store_i32_le(output, round * 4, duplicate);
        std::free(data);
    }
    return static_cast<std::int64_t>(output_bytes);
}
