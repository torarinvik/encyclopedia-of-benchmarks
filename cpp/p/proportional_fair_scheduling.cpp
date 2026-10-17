#include <cstddef>
#include <cstdint>

static void store_i64_le(std::uint8_t *output, std::size_t position, std::int64_t value) noexcept
{
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[position + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}

extern "C" std::int64_t proportional_fair_scheduling(
    const std::int64_t *values, std::size_t length, std::uint8_t *output,
    std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 2 || length > 131) return -1;
    if (values[0] < 0 || values[0] > 64 || values[1] < 1 || values[1] > 1000000) return -1;
    const auto process_count = static_cast<std::size_t>(values[0]);
    const auto total_resources = values[1];
    if (length != 2 + 2 * process_count) return -1;

    std::int64_t name_ids[64], weights[64];
    std::int64_t total_weight = 0;
    for (std::size_t process = 0; process < process_count; ++process) {
        const auto name_id = values[2 + 2 * process];
        const auto weight = values[3 + 2 * process];
        if (name_id < INT32_MIN || name_id > INT32_MAX || weight < 1 || weight > 1000000) return -1;
        name_ids[process] = name_id;
        weights[process] = weight;
        total_weight += weight;
    }

    if (process_count == 0) return 0;
    const auto required = process_count * 16;
    if (output == nullptr || output_capacity < required) return -2;
    for (std::size_t process = 0; process < process_count; ++process) {
        const double quotient = static_cast<double>(weights[process]) / static_cast<double>(total_weight);
        const double share = quotient * static_cast<double>(total_resources);
        const auto allocation = static_cast<std::int32_t>(share);
        store_i64_le(output, process * 16, name_ids[process]);
        store_i64_le(output, process * 16 + 8, allocation);
    }
    return static_cast<std::int64_t>(required);
}
