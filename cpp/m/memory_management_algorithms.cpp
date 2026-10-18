#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_block_count = 16;
constexpr std::size_t max_process_count = 32;
constexpr std::size_t max_input_length = 52;
constexpr std::size_t max_output_bytes = 256;
constexpr std::int64_t no_allocation = -255;

void write_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept
{
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & UINT64_C(0xff));
        bits >>= 8;
    }
}
}

extern "C" std::int64_t memory_management_algorithms(const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 3 || length > max_input_length) return -1;
    const auto policy = input[0];
    if (policy < 0 || policy > 3 || input[1] < 1 || input[1] > static_cast<std::int64_t>(max_block_count) ||
        input[2] < 0 || input[2] > static_cast<std::int64_t>(max_process_count)) return -1;
    const auto block_count = static_cast<std::size_t>(input[1]);
    const auto process_count = static_cast<std::size_t>(input[2]);
    if (length != 3 + block_count + process_count) return -1;

    std::array<std::int64_t, max_block_count> blocks{};
    std::array<std::int64_t, max_process_count> processes{};
    for (std::size_t index = 0; index < block_count; ++index) {
        const auto size = input[3 + index];
        if (size < 1 || size > 10000) return -1;
        blocks[index] = size;
    }
    for (std::size_t index = 0; index < process_count; ++index) {
        const auto size = input[3 + block_count + index];
        if (size < 1 || size > 10000) return -1;
        processes[index] = size;
    }

    std::array<std::int64_t, max_process_count> allocations{};
    std::int64_t next_fit_counter = 0;
    for (std::size_t process_index = 0; process_index < process_count; ++process_index) {
        const auto process = processes[process_index];
        auto selected = no_allocation;
        if (policy == 0) {
            for (std::size_t index = 0; index < block_count; ++index) {
                if (blocks[index] >= process) { selected = static_cast<std::int64_t>(index); break; }
            }
        } else if (policy == 1) {
            auto min_diff = blocks[0];
            for (std::size_t index = 1; index < block_count; ++index)
                if (blocks[index] > min_diff) min_diff = blocks[index];
            for (std::size_t index = 0; index < block_count; ++index) {
                const auto difference = blocks[index] - process;
                if (difference < min_diff && difference >= 0) {
                    min_diff = difference;
                    selected = static_cast<std::int64_t>(index);
                }
            }
        } else if (policy == 2) {
            std::size_t index = 0;
            for (std::size_t candidate = 1; candidate < block_count; ++candidate)
                if (blocks[candidate] > blocks[index]) index = candidate;
            if (blocks[index] >= process) selected = static_cast<std::int64_t>(index);
        } else {
            bool found = false;
            for (std::size_t offset = 0; offset < block_count; ++offset) {
                if (next_fit_counter + static_cast<std::int64_t>(offset) >= static_cast<std::int64_t>(block_count))
                    next_fit_counter = -static_cast<std::int64_t>(offset);
                const auto index = static_cast<std::size_t>(static_cast<std::int64_t>(offset) + next_fit_counter);
                if (blocks[index] >= process) {
                    next_fit_counter += static_cast<std::int64_t>(offset);
                    selected = next_fit_counter;
                    found = true;
                    break;
                }
            }
            if (!found) next_fit_counter += static_cast<std::int64_t>(block_count);
        }
        allocations[process_index] = selected;
        if (selected != no_allocation) blocks[static_cast<std::size_t>(selected)] -= process;
    }

    const auto output_bytes = process_count * 8;
    if (output_bytes > max_output_bytes) return -1;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t index = 0; index < process_count; ++index)
        write_i64_le(output, index * 8, allocations[index]);
    return static_cast<std::int64_t>(output_bytes);
}
