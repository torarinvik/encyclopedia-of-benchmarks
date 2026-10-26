#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxTasks = 8;
constexpr std::size_t kMaxInput = 17;
constexpr std::size_t kMaxOutputBytes = 80;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t rate_monotonic_scheduling(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept
{
    if (input == nullptr || length < 3 || length > kMaxInput) return -1;
    const auto count_value = input[0];
    if (count_value < 1 || count_value > static_cast<std::int64_t>(kMaxTasks) ||
        length != 1 + 2 * static_cast<std::size_t>(count_value)) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    std::int64_t execution[kMaxTasks]{};
    std::int64_t period[kMaxTasks]{};
    std::size_t order[kMaxTasks]{};
    std::int64_t response[kMaxTasks];
    for (std::size_t task = 0; task < count; ++task) {
        execution[task] = input[1 + 2 * task];
        period[task] = input[2 + 2 * task];
        if (execution[task] < 1 || execution[task] > 16 || period[task] < 1 || period[task] > 32) return -1;
        order[task] = task;
        response[task] = -1;
    }
    for (std::size_t index = 1; index < count; ++index) {
        const auto key = order[index];
        auto position = index;
        while (position > 0 && (period[order[position - 1]] > period[key] ||
               (period[order[position - 1]] == period[key] && order[position - 1] > key))) {
            order[position] = order[position - 1];
            --position;
        }
        order[position] = key;
    }

    std::int64_t schedulable = 1;
    std::int64_t failed_task = -1;
    for (std::size_t rank = 0; rank < count; ++rank) {
        const auto target = order[rank];
        auto remaining_target = execution[target];
        std::int64_t active[kMaxTasks]{};
        std::int64_t elapsed = 0;
        while (remaining_target > 0 && elapsed < period[target]) {
            for (std::size_t higher_rank = 0; higher_rank < rank; ++higher_rank) {
                const auto higher = order[higher_rank];
                if (elapsed % period[higher] == 0) active[higher] += execution[higher];
            }
            std::size_t selected = kMaxTasks;
            for (std::size_t higher_rank = 0; higher_rank < rank; ++higher_rank) {
                const auto higher = order[higher_rank];
                if (active[higher] > 0) { selected = higher; break; }
            }
            if (selected < kMaxTasks) --active[selected];
            else --remaining_target;
            ++elapsed;
        }
        if (remaining_target > 0) {
            schedulable = 0;
            failed_task = static_cast<std::int64_t>(target);
            break;
        }
        response[target] = elapsed;
    }

    const std::size_t output_bytes = 8 * (count + 2);
    if (output == nullptr || capacity < output_bytes) return -2;
    std::uint8_t staged[kMaxOutputBytes]{};
    store_i64_le(staged, 0, schedulable);
    store_i64_le(staged, 8, failed_task);
    for (std::size_t task = 0; task < count; ++task) store_i64_le(staged, 8 * (task + 2), response[task]);
    for (std::size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return static_cast<std::int64_t>(output_bytes);
}
