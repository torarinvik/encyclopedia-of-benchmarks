#include <array>
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t MaxJobs = 8, MaxInput = 18, MaxOutput = 112; }

extern "C" std::int64_t shortest_elapsed_time_first(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 1 || length > MaxInput) return -1;
    const auto n64 = input[0];
    if (n64 < 0 || n64 > static_cast<std::int64_t>(MaxJobs) || length != 1 + 2 * static_cast<std::size_t>(n64)) return -1;
    const auto n = static_cast<std::size_t>(n64);
    std::array<std::int64_t, MaxJobs> release{}, remaining{}, attained{};
    for (std::size_t job = 0; job < n; ++job) {
        release[job] = input[1 + 2 * job]; remaining[job] = input[2 + 2 * job];
        if (release[job] < 0 || release[job] > 16 || remaining[job] < 1 || remaining[job] > 12) return -1;
    }
    if (!output) return -2;
    std::array<std::uint8_t, MaxOutput> trace{};
    std::size_t time = 0, completed = 0;
    while (completed < n && time < MaxOutput) {
        std::size_t chosen = n;
        for (std::size_t job = 0; job < n; ++job)
            if (release[job] <= static_cast<std::int64_t>(time) && remaining[job] > 0 &&
                (chosen == n || attained[job] < attained[chosen])) chosen = job;
        if (chosen == n) trace[time] = 0;
        else {
            trace[time] = static_cast<std::uint8_t>(chosen + 1);
            ++attained[chosen];
            if (--remaining[chosen] == 0) ++completed;
        }
        ++time;
    }
    if (completed != n) return -1;
    if (capacity < time) return -2;
    for (std::size_t t = 0; t < time; ++t) output[t] = trace[t];
    return static_cast<std::int64_t>(time);
}
