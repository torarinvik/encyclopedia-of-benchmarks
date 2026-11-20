#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxSegments = 24;
constexpr std::size_t kMaxInput = 98;
constexpr std::int64_t kCoordMin = -100;
constexpr std::int64_t kCoordMax = 100;

struct Segment { std::int64_t x1, y1, x2, y2; };
struct Event { std::int64_t x; int id; bool start; };

std::int64_t orientation(std::int64_t ax, std::int64_t ay, std::int64_t bx,
                         std::int64_t by, std::int64_t cx, std::int64_t cy) {
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
}

bool between(std::int64_t a, std::int64_t b, std::int64_t point) {
    return (a <= b && a <= point && point <= b) || (b < a && b <= point && point <= a);
}

bool onSegment(std::int64_t ax, std::int64_t ay, std::int64_t bx, std::int64_t by,
               std::int64_t px, std::int64_t py) {
    return orientation(ax, ay, bx, by, px, py) == 0 &&
           between(ax, bx, px) && between(ay, by, py);
}

bool intersects(const Segment& a, const Segment& b) {
    const auto abC = orientation(a.x1, a.y1, a.x2, a.y2, b.x1, b.y1);
    const auto abD = orientation(a.x1, a.y1, a.x2, a.y2, b.x2, b.y2);
    const auto cdA = orientation(b.x1, b.y1, b.x2, b.y2, a.x1, a.y1);
    const auto cdB = orientation(b.x1, b.y1, b.x2, b.y2, a.x2, a.y2);
    if (abC == 0 && onSegment(a.x1, a.y1, a.x2, a.y2, b.x1, b.y1)) return true;
    if (abD == 0 && onSegment(a.x1, a.y1, a.x2, a.y2, b.x2, b.y2)) return true;
    if (cdA == 0 && onSegment(b.x1, b.y1, b.x2, b.y2, a.x1, a.y1)) return true;
    if (cdB == 0 && onSegment(b.x1, b.y1, b.x2, b.y2, a.x2, a.y2)) return true;
    return ((abC < 0 && abD > 0) || (abC > 0 && abD < 0)) &&
           ((cdA < 0 && cdB > 0) || (cdA > 0 && cdB < 0));
}

int compareAtX(const Segment& a, int idA, const Segment& b, int idB, std::int64_t x) {
    const auto adx = a.x2 - a.x1, bdx = b.x2 - b.x1;
    const auto aNum = a.y1 * adx + (a.y2 - a.y1) * (x - a.x1);
    const auto bNum = b.y1 * bdx + (b.y2 - b.y1) * (x - b.x1);
    const auto left = aNum * bdx, right = bNum * adx;
    if (left != right) return left < right ? -1 : 1;
    const auto aSlope = (a.y2 - a.y1) * bdx;
    const auto bSlope = (b.y2 - b.y1) * adx;
    if (aSlope != bSlope) return aSlope < bSlope ? -1 : 1;
    return (idA > idB) - (idA < idB);
}
}

extern "C" std::int64_t intersecting_segments_sweep(const std::int64_t* input,
                                                     std::size_t length) {
    if (input == nullptr || length < 1 || length > kMaxInput) return -1;
    const auto countRaw = input[0];
    if (countRaw < 0 || countRaw > kMaxSegments || length != 1 + 4 * static_cast<std::size_t>(countRaw)) return -1;
    const int count = static_cast<int>(countRaw);
    std::array<bool, 201> usedX{};
    std::array<Segment, kMaxSegments> segments{};
    std::array<Event, 2 * kMaxSegments> events{};
    int eventCount = 0;
    for (int id = 0; id < count; ++id) {
        const auto offset = 1 + 4 * static_cast<std::size_t>(id);
        const Segment segment{input[offset], input[offset + 1], input[offset + 2], input[offset + 3]};
        if (segment.x1 < kCoordMin || segment.x1 > kCoordMax ||
            segment.x2 < kCoordMin || segment.x2 > kCoordMax ||
            segment.y1 < kCoordMin || segment.y1 > kCoordMax ||
            segment.y2 < kCoordMin || segment.y2 > kCoordMax || segment.x1 >= segment.x2) return -1;
        const int firstX = static_cast<int>(segment.x1 - kCoordMin);
        const int secondX = static_cast<int>(segment.x2 - kCoordMin);
        if (usedX[firstX] || usedX[secondX]) return -1;
        usedX[firstX] = usedX[secondX] = true;
        segments[id] = segment;
        events[eventCount++] = {segment.x1, id, true};
        events[eventCount++] = {segment.x2, id, false};
    }
    for (int index = 1; index < eventCount; ++index) {
        const Event item = events[index];
        int position = index;
        while (position > 0 && events[position - 1].x > item.x) {
            events[position] = events[position - 1];
            --position;
        }
        events[position] = item;
    }

    std::array<int, kMaxSegments> active{};
    int activeCount = 0;
    for (int eventIndex = 0; eventIndex < eventCount; ++eventIndex) {
        const auto event = events[eventIndex];
        if (event.start) {
            int position = 0;
            while (position < activeCount && compareAtX(segments[active[position]], active[position],
                    segments[event.id], event.id, event.x) < 0) ++position;
            if (position > 0 && intersects(segments[active[position - 1]], segments[event.id])) return 1;
            if (position < activeCount && intersects(segments[active[position]], segments[event.id])) return 1;
            for (int move = activeCount; move > position; --move) active[move] = active[move - 1];
            active[position] = event.id;
            ++activeCount;
        } else {
            int position = 0;
            while (position < activeCount && active[position] != event.id) ++position;
            if (position == activeCount) return -1;
            if (position > 0 && position + 1 < activeCount &&
                intersects(segments[active[position - 1]], segments[active[position + 1]])) return 1;
            for (int move = position; move + 1 < activeCount; ++move) active[move] = active[move + 1];
            --activeCount;
        }
    }
    return 0;
}
