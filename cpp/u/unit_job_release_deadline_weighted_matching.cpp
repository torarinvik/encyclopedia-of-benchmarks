#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <numeric>

namespace {
struct Schedule {
    std::array<int, 32> release{}, deadline{}, slots{}, seen{};
    bool assign(int job) {
        for (int slot = release[job]; slot <= deadline[job]; ++slot) {
            if (seen[slot]) continue;
            seen[slot] = 1;
            if (slots[slot] == -1 || assign(slots[slot])) { slots[slot] = job; return true; }
        }
        return false;
    }
};
}
extern "C" std::int64_t unit_job_release_deadline_weighted_matching(const std::int64_t* input, std::size_t length) {
    if (!input || length < 1 || length > 98 || input[0] < 0 || input[0] > 32) return -1;
    const int n = static_cast<int>(input[0]);
    if (length != static_cast<std::size_t>(1+3*n)) return -1;
    Schedule s; s.slots.fill(-1);
    std::array<std::int64_t, 32> weights{}; std::array<int, 32> order{};
    for (int i = 0; i < n; ++i) {
        auto r = input[1+3*i], d = input[2+3*i], w = input[3+3*i];
        if (r < 0 || d < r || d >= 32 || w < 0 || w > 1000000) return -1;
        s.release[i] = static_cast<int>(r); s.deadline[i] = static_cast<int>(d); weights[i] = w; order[i] = i;
    }
    std::stable_sort(order.begin(), order.begin()+n, [&](int a, int b) { return weights[a] > weights[b]; });
    std::int64_t total = 0;
    for (int i = 0; i < n; ++i) { s.seen.fill(0); if (s.assign(order[i])) total += weights[order[i]]; }
    return total;
}
