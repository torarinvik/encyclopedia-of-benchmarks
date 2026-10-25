#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_children = 8;
bool valid_box(const std::int64_t *v, std::size_t at) {
    for (std::size_t d = 0; d < 4; ++d)
        if (v[at + d] < -8 || v[at + d] > 8 || v[at + 4 + d] < -8 || v[at + 4 + d] > 8 || v[at + d] >= v[at + 4 + d]) return false;
    return true;
}
std::int64_t volume_at(const std::int64_t *v, std::size_t at) {
    std::int64_t result = 1;
    for (std::size_t d = 0; d < 4; ++d) result *= v[at + 4 + d] - v[at + d];
    return result;
}
std::int64_t penalty_at(const std::int64_t *v, std::size_t child, std::size_t incoming) {
    std::int64_t joined_volume = 1;
    for (std::size_t d = 0; d < 4; ++d) {
        const auto lo = v[child + d] < v[incoming + d] ? v[child + d] : v[incoming + d];
        const auto child_hi = v[child + 4 + d], incoming_hi = v[incoming + 4 + d];
        const auto hi = child_hi > incoming_hi ? child_hi : incoming_hi;
        joined_volume *= hi - lo;
    }
    return joined_volume - volume_at(v, child);
}
}

extern "C" std::int64_t versabench_dbms_choose_entry(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length < 1 || length > 74) return -1;
    const auto raw_count = values[0];
    if (raw_count < 1 || raw_count > static_cast<std::int64_t>(max_children)) return -1;
    const auto count = static_cast<std::size_t>(raw_count);
    if (length != 1 + 8 * count + 8) return -1;
    const std::size_t incoming = 1 + 8 * count;
    for (std::size_t i = 0; i < count; ++i) if (!valid_box(values, 1 + 8 * i)) return -1;
    if (!valid_box(values, incoming)) return -1;
    std::size_t best = 0;
    auto best_penalty = penalty_at(values, 1, incoming);
    for (std::size_t i = 1; i < count; ++i) {
        const auto candidate = penalty_at(values, 1 + 8 * i, incoming);
        if (candidate < best_penalty) { best = i; best_penalty = candidate; }
    }
    return static_cast<std::int64_t>(best);
}
