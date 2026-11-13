#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t queue_capacity = 16;
constexpr std::size_t max_parseable_length = 65;
constexpr std::int64_t value_min = -1000;
constexpr std::int64_t value_max = 1000;
constexpr std::int64_t checksum_offset = 1001;

std::int64_t solve(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 1 || length > max_parseable_length) return -1;
    if (input[0] < 0 || input[0] > 32) return -1;

    std::int64_t in_values[queue_capacity], in_minimums[queue_capacity];
    std::int64_t out_values[queue_capacity], out_minimums[queue_capacity];
    std::size_t in_count = 0, out_count = 0, cursor = 1;
    const auto operation_count = static_cast<std::size_t>(input[0]);
    std::int64_t checksum = 0;

    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        if (cursor >= length) return -1;
        const auto opcode = input[cursor++];
        if (opcode == 0) {
            if (cursor >= length) return -1;
            const auto value = input[cursor++];
            if (value < value_min || value > value_max ||
                in_count + out_count >= queue_capacity) return -1;
            in_values[in_count] = value;
            in_minimums[in_count] = in_count == 0 || value < in_minimums[in_count - 1]
                ? value : in_minimums[in_count - 1];
            ++in_count;
        } else if (opcode == 1) {
            if (in_count + out_count == 0) return -1;
            if (out_count == 0) {
                while (in_count > 0) {
                    const auto value = in_values[--in_count];
                    out_values[out_count] = value;
                    out_minimums[out_count] = out_count == 0 || value < out_minimums[out_count - 1]
                        ? value : out_minimums[out_count - 1];
                    ++out_count;
                }
            }
            const auto observed = out_values[--out_count];
            checksum += static_cast<std::int64_t>(operation + 1) * (observed + checksum_offset);
        } else if (opcode == 2) {
            if (in_count + out_count == 0) return -1;
            std::int64_t observed;
            if (in_count == 0) observed = out_minimums[out_count - 1];
            else if (out_count == 0) observed = in_minimums[in_count - 1];
            else observed = in_minimums[in_count - 1] < out_minimums[out_count - 1]
                ? in_minimums[in_count - 1] : out_minimums[out_count - 1];
            checksum += static_cast<std::int64_t>(operation + 1) * (observed + checksum_offset);
        } else return -1;
    }
    if (cursor != length) return -1;

    std::size_t position = 0;
    for (std::size_t index = out_count; index > 0; --index) {
        ++position;
        checksum += static_cast<std::int64_t>(position) *
                    (out_values[index - 1] + checksum_offset);
    }
    for (std::size_t index = 0; index < in_count; ++index) {
        ++position;
        checksum += static_cast<std::int64_t>(position) * (in_values[index] + checksum_offset);
    }
    return checksum;
}
}  // namespace

extern "C" std::int64_t minimum_queue_two_stacks(
    const std::int64_t* input, std::size_t length) noexcept {
    return solve(input, length);
}
