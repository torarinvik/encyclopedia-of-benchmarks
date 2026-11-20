#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_rectangles = 64;
constexpr std::size_t max_events = 2 * max_rectangles;
constexpr std::size_t tree_size = 512;
constexpr std::int64_t min_coordinate = -1'000'000'000;
constexpr std::int64_t max_coordinate = 1'000'000'000;

struct Event { std::int64_t x, y1, y2, delta; };

template <std::size_t N>
void sort_i64(std::array<std::int64_t, N>& values, std::size_t count) noexcept {
    auto sift = [&](std::size_t root, std::size_t end) {
        while (root * 2 + 1 < end) {
            auto child = root * 2 + 1;
            if (child + 1 < end && values[child] < values[child + 1]) ++child;
            if (values[root] >= values[child]) return;
            auto value = values[root]; values[root] = values[child]; values[child] = value;
            root = child;
        }
    };
    for (auto start = count / 2; start > 0; --start) sift(start - 1, count);
    for (auto end = count; end > 1; --end) {
        auto value = values[0]; values[0] = values[end - 1]; values[end - 1] = value;
        sift(0, end - 1);
    }
}

void sort_events(std::array<Event, max_events>& events, std::size_t count) noexcept {
    auto sift = [&](std::size_t root, std::size_t end) {
        while (root * 2 + 1 < end) {
            auto child = root * 2 + 1;
            if (child + 1 < end && events[child].x < events[child + 1].x) ++child;
            if (events[root].x >= events[child].x) return;
            auto value = events[root]; events[root] = events[child]; events[child] = value;
            root = child;
        }
    };
    for (auto start = count / 2; start > 0; --start) sift(start - 1, count);
    for (auto end = count; end > 1; --end) {
        auto value = events[0]; events[0] = events[end - 1]; events[end - 1] = value;
        sift(0, end - 1);
    }
}

std::size_t lower_bound(const std::array<std::int64_t, max_events>& values,
                        std::size_t count, std::int64_t target) noexcept {
    std::size_t low = 0, high = count;
    while (low < high) {
        auto middle = low + (high - low) / 2;
        if (values[middle] < target) low = middle + 1;
        else high = middle;
    }
    return low;
}

void update(std::size_t node, std::size_t left, std::size_t right,
            std::size_t ql, std::size_t qr, std::int64_t delta,
            const std::array<std::int64_t, max_events>& ys,
            std::array<std::int64_t, tree_size>& cover,
            std::array<std::int64_t, tree_size>& covered) noexcept {
    if (ql <= left && right <= qr) cover[node] += delta;
    else {
        auto middle = left + (right - left) / 2;
        if (ql < middle) update(node * 2, left, middle, ql, qr, delta, ys, cover, covered);
        if (qr > middle) update(node * 2 + 1, middle, right, ql, qr, delta, ys, cover, covered);
    }
    if (cover[node] > 0) covered[node] = ys[right] - ys[left];
    else if (right - left == 1) covered[node] = 0;
    else covered[node] = covered[node * 2] + covered[node * 2 + 1];
}
}

extern "C" std::int64_t rectangle_union_area_sweep(const std::int64_t *input,
                                                       std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > 258) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_rectangles)) return -1;
    const auto count = static_cast<std::size_t>(input[0]);
    if (length != 1 + 4 * count) return -1;
    std::array<std::int64_t, max_events> ys{};
    std::array<Event, max_events> events{};
    std::size_t y_count = 0, event_count = 0;
    for (std::size_t i = 0; i < count; ++i) {
        const auto x1 = input[1 + 4 * i], y1 = input[2 + 4 * i];
        const auto x2 = input[3 + 4 * i], y2 = input[4 + 4 * i];
        if (x1 < min_coordinate || x1 > max_coordinate || x2 < min_coordinate || x2 > max_coordinate
                || y1 < min_coordinate || y1 > max_coordinate || y2 < min_coordinate || y2 > max_coordinate
                || x1 >= x2 || y1 >= y2) return -1;
        ys[y_count++] = y1; ys[y_count++] = y2;
        events[event_count++] = {x1, y1, y2, 1};
        events[event_count++] = {x2, y1, y2, -1};
    }
    if (count == 0) return 0;
    sort_i64(ys, y_count);
    std::size_t unique_count = 1;
    for (std::size_t i = 1; i < y_count; ++i)
        if (ys[i] != ys[unique_count - 1]) ys[unique_count++] = ys[i];
    sort_events(events, event_count);
    std::array<std::int64_t, tree_size> cover{}, covered{};
    std::int64_t area = 0, previous_x = events[0].x;
    const auto intervals = unique_count - 1;
    for (std::size_t event = 0; event < event_count;) {
        const auto x = events[event].x;
        area += covered[1] * (x - previous_x);
        auto end = event;
        while (end < event_count && events[end].x == x) ++end;
        for (int pass = 1; pass >= -1; pass -= 2)
            for (auto i = event; i < end; ++i) if (events[i].delta == pass)
                update(1, 0, intervals, lower_bound(ys, unique_count, events[i].y1),
                       lower_bound(ys, unique_count, events[i].y2), events[i].delta, ys, cover, covered);
        previous_x = x;
        event = end;
    }
    return area;
}
