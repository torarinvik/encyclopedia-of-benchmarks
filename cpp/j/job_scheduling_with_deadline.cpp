#include <cstddef>
#include <cstdint>

extern "C" std::int64_t job_scheduling_with_deadline(
    const std::int64_t *packed, std::size_t length) noexcept {
    constexpr std::size_t MaxJobs = 128;
    constexpr std::int64_t MaxDeadline = 32;
    constexpr std::int64_t MaxId = 2147483647;
    constexpr std::int64_t MaxProfit = 1000000;
    constexpr std::int64_t PackBase = 4294967296;
    if (packed == nullptr || length < 1 || length > 513) return -1;
    const std::int64_t count_value = packed[0];
    if (count_value < 0 || count_value > static_cast<std::int64_t>(MaxJobs) ||
        length != 1 + static_cast<std::size_t>(count_value) * 4) return -1;
    const auto count = static_cast<std::size_t>(count_value);

    std::int64_t ids[MaxJobs]{}, arrivals[MaxJobs]{}, deadlines[MaxJobs]{}, profits[MaxJobs]{};
    std::int64_t max_deadline = 0;
    for (std::size_t i = 0; i < count; ++i) {
        const auto base = 1 + i * 4;
        ids[i] = packed[base];
        arrivals[i] = packed[base + 1];
        deadlines[i] = packed[base + 2];
        profits[i] = packed[base + 3];
        if (ids[i] < 0 || ids[i] > MaxId || arrivals[i] < 1 || arrivals[i] > MaxDeadline ||
            deadlines[i] < 1 || deadlines[i] > MaxDeadline ||
            profits[i] < -MaxProfit || profits[i] > MaxProfit) return -1;
        for (std::size_t previous = 0; previous < i; ++previous)
            if (ids[previous] == ids[i]) return -1;
        if (deadlines[i] > max_deadline) max_deadline = deadlines[i];
    }

    // Stable insertion sort preserves input order for equal profits.
    for (std::size_t i = 1; i < count; ++i) {
        const auto key_id = ids[i], key_arrival = arrivals[i];
        const auto key_deadline = deadlines[i], key_profit = profits[i];
        std::size_t position = i;
        while (position > 0 && profits[position - 1] < key_profit) {
            ids[position] = ids[position - 1];
            arrivals[position] = arrivals[position - 1];
            deadlines[position] = deadlines[position - 1];
            profits[position] = profits[position - 1];
            --position;
        }
        ids[position] = key_id;
        arrivals[position] = key_arrival;
        deadlines[position] = key_deadline;
        profits[position] = key_profit;
    }

    bool occupied[32]{};
    std::int64_t scheduled = 0, total_profit = 0;
    for (std::size_t i = 0; i < count; ++i) {
        if (arrivals[i] > deadlines[i]) continue;
        const auto last_slot = deadlines[i] - 1 < max_deadline - 1
            ? deadlines[i] - 1 : max_deadline - 1;
        for (auto slot = last_slot; slot >= arrivals[i] - 1; --slot) {
            if (!occupied[static_cast<std::size_t>(slot)]) {
                occupied[static_cast<std::size_t>(slot)] = true;
                ++scheduled;
                total_profit += profits[i];
                break;
            }
        }
    }
    const auto low_word = total_profit < 0 ? total_profit + PackBase : total_profit;
    return scheduled * PackBase + low_word;
}
