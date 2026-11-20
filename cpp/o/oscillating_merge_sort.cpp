/* Bounded multi-tape merge with alternating run directions and backward reads. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_values = 1024;
constexpr std::size_t max_parts = 2;
constexpr std::size_t initial_run_size = 16;

std::size_t build_run(const std::int64_t *values, std::size_t value_count,
                      std::size_t run_size, std::size_t merge_inputs,
                      std::size_t first_run, std::size_t run_count,
                      bool ascending, std::int64_t *output) noexcept
{
    if (run_count == 1) {
        const std::size_t start = first_run * run_size;
        std::size_t length = value_count - start;
        if (length > run_size) length = run_size;
        for (std::size_t i = 0; i < length; ++i) output[i] = values[start + i];
        for (std::size_t i = 1; i < length; ++i) {
            const auto value = output[i];
            auto position = i;
            while (position > 0 && (ascending ? value < output[position - 1]
                                               : value > output[position - 1])) {
                output[position] = output[position - 1];
                --position;
            }
            output[position] = value;
        }
        return length;
    }

    std::int64_t children[max_parts][max_values]{};
    std::size_t lengths[max_parts]{};
    std::size_t positions[max_parts]{};
    const auto quotient = run_count / merge_inputs;
    const auto remainder = run_count % merge_inputs;
    auto next_run = first_run;
    std::size_t total = 0;
    for (std::size_t lane = 0; lane < merge_inputs; ++lane) {
        const auto child_count = quotient + (lane < remainder ? 1 : 0);
        if (child_count == 0) continue;
        lengths[lane] = build_run(values, value_count, run_size, merge_inputs,
                                  next_run, child_count, !ascending, children[lane]);
        next_run += child_count;
        total += lengths[lane];
    }

    for (std::size_t out = 0; out < total; ++out) {
        auto best_lane = max_parts;
        std::int64_t best_value = 0;
        for (std::size_t lane = 0; lane < merge_inputs; ++lane) {
            if (positions[lane] >= lengths[lane]) continue;
            const auto candidate = children[lane][lengths[lane] - 1 - positions[lane]];
            if (best_lane == max_parts || (ascending ? candidate < best_value
                                                       : candidate > best_value)) {
                best_lane = lane;
                best_value = candidate;
            }
        }
        output[out] = best_value;
        ++positions[best_lane];
    }
    return total;
}
}

extern "C" void oscillating_merge_sort(std::int64_t *values, std::size_t length) noexcept
{
    if (length > max_values || (length != 0 && values == nullptr) || length == 0) return;
    std::int64_t sorted[max_values]{};
    const auto run_count = (length + initial_run_size - 1) / initial_run_size;
    build_run(values, length, initial_run_size, max_parts, 0, run_count, true, sorted);
    for (std::size_t i = 0; i < length; ++i) values[i] = sorted[i];
}
