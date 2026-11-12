#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_jobs = 8;
constexpr std::int64_t max_time = 1000;

std::int64_t solve(const std::int64_t* input, std::size_t length) {
    if (!input || length < 1 || input[0] < 1 || input[0] > max_jobs) return -1;
    const int count = static_cast<int>(input[0]);
    if (length != static_cast<std::size_t>(1 + 2 * count)) return -1;
    std::array<std::int64_t, max_jobs> first{}, second{};
    std::array<int, max_jobs> early{}, late{};
    int early_count = 0, late_count = 0;
    for (int job = 0; job < count; ++job) {
        first[job] = input[1 + 2 * job];
        second[job] = input[2 + 2 * job];
        if (first[job] < 0 || first[job] > max_time || second[job] < 0 || second[job] > max_time) return -1;
        const bool is_early = first[job] < second[job];
        int position = is_early ? early_count : late_count;
        while (position > 0) {
            const int previous = is_early ? early[position - 1] : late[position - 1];
            const bool comes_before = is_early
                ? (first[job] < first[previous] || (first[job] == first[previous] && job < previous))
                : (second[job] > second[previous] || (second[job] == second[previous] && job < previous));
            if (!comes_before) break;
            if (is_early) early[position] = previous; else late[position] = previous;
            --position;
        }
        if (is_early) { early[position] = job; ++early_count; }
        else { late[position] = job; ++late_count; }
    }
    std::int64_t first_finish = 0, second_finish = 0;
    for (int index = 0; index < count; ++index) {
        const int job = index < early_count ? early[index] : late[index - early_count];
        first_finish += first[job];
        if (second_finish < first_finish) second_finish = first_finish;
        second_finish += second[job];
    }
    return second_finish;
}
}

extern "C" std::int64_t johnson_two_machine_flow_shop(const std::int64_t* input,
        std::size_t length) noexcept {
    return solve(input, length);
}
