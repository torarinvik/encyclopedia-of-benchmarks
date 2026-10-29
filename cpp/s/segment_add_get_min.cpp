#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxInitialSegments = 16;
constexpr std::int64_t kMaxOperations = 32;
constexpr std::int64_t kDomainLow = -32;
constexpr std::int64_t kDomainHigh = 31;
constexpr std::int64_t kDomainRight = 32;
constexpr std::int64_t kCoefficientLimit = 1000;
constexpr std::int64_t kInfinity = 1'000'000'000'000;
constexpr std::int64_t kChecksumOffset = 33'001;
constexpr std::size_t kTreeCapacity = 4 * 64 + 8;
constexpr std::size_t kMaxInputLength = 2 + 4 * 16 + 5 * 32;

struct Node {
    std::int64_t slope = 0;
    std::int64_t intercept = 0;
    bool occupied = false;
};

struct SegmentLiChao {
    std::array<Node, kTreeCapacity> nodes{};

    static std::int64_t evaluate(std::int64_t slope, std::int64_t intercept, std::int64_t x)
    {
        return slope * x + intercept;
    }

    void add_line(std::size_t node, std::int64_t low, std::int64_t high,
                  std::int64_t slope, std::int64_t intercept)
    {
        Node &current = nodes[node];
        if (!current.occupied) {
            current = {slope, intercept, true};
            return;
        }
        const std::int64_t middle = low + (high - low) / 2;
        if (evaluate(slope, intercept, middle) < evaluate(current.slope, current.intercept, middle)) {
            const std::int64_t old_slope = current.slope;
            const std::int64_t old_intercept = current.intercept;
            current.slope = slope;
            current.intercept = intercept;
            slope = old_slope;
            intercept = old_intercept;
        }
        if (low == high) return;
        if (evaluate(slope, intercept, low) < evaluate(current.slope, current.intercept, low)) {
            add_line(2 * node, low, middle, slope, intercept);
        } else if (evaluate(slope, intercept, high) < evaluate(current.slope, current.intercept, high)) {
            add_line(2 * node + 1, middle + 1, high, slope, intercept);
        }
    }

    void add_segment(std::size_t node, std::int64_t low, std::int64_t high,
                     std::int64_t query_low, std::int64_t query_high,
                     std::int64_t slope, std::int64_t intercept)
    {
        if (query_high <= low || high < query_low) return;
        if (query_low <= low && high < query_high) {
            add_line(node, low, high, slope, intercept);
            return;
        }
        const std::int64_t middle = low + (high - low) / 2;
        add_segment(2 * node, low, middle, query_low, query_high, slope, intercept);
        add_segment(2 * node + 1, middle + 1, high, query_low, query_high, slope, intercept);
    }

    std::int64_t minimum_at(std::size_t node, std::int64_t low,
                            std::int64_t high, std::int64_t x) const
    {
        const Node &current = nodes[node];
        std::int64_t best = current.occupied ? evaluate(current.slope, current.intercept, x) : kInfinity;
        if (low == high) return best;
        const std::int64_t middle = low + (high - low) / 2;
        const bool go_left = x <= middle;
        const std::int64_t nested = minimum_at(go_left ? 2 * node : 2 * node + 1,
            go_left ? low : middle + 1, go_left ? middle : high, x);
        return nested < best ? nested : best;
    }
};

bool valid_segment(std::int64_t left, std::int64_t right,
                   std::int64_t slope, std::int64_t intercept)
{
    return left >= kDomainLow && left < right && right <= kDomainRight
        && slope >= -kCoefficientLimit && slope <= kCoefficientLimit
        && intercept >= -kCoefficientLimit && intercept <= kCoefficientLimit;
}
} // namespace

extern "C" std::int64_t segment_add_get_min(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length < 2 || length > kMaxInputLength) return -1;
    const std::int64_t initial_value = values[0];
    const std::int64_t operation_value = values[1];
    if (initial_value < 0 || initial_value > kMaxInitialSegments
        || operation_value < 0 || operation_value > kMaxOperations) return -1;
    const std::size_t initial_count = static_cast<std::size_t>(initial_value);
    const std::size_t operation_count = static_cast<std::size_t>(operation_value);

    SegmentLiChao tree;
    std::size_t position = 2;
    for (std::size_t index = 0; index < initial_count; ++index) {
        if (length - position < 4) return -1;
        const std::int64_t left = values[position];
        const std::int64_t right = values[position + 1];
        const std::int64_t slope = values[position + 2];
        const std::int64_t intercept = values[position + 3];
        if (!valid_segment(left, right, slope, intercept)) return -1;
        tree.add_segment(1, kDomainLow, kDomainHigh, left, right, slope, intercept);
        position += 4;
    }

    std::int64_t checksum = 0;
    std::int64_t query_number = 0;
    for (std::size_t index = 0; index < operation_count; ++index) {
        if (position >= length) return -1;
        const std::int64_t opcode = values[position++];
        if (opcode == 0) {
            if (length - position < 4) return -1;
            const std::int64_t left = values[position];
            const std::int64_t right = values[position + 1];
            const std::int64_t slope = values[position + 2];
            const std::int64_t intercept = values[position + 3];
            if (!valid_segment(left, right, slope, intercept)) return -1;
            tree.add_segment(1, kDomainLow, kDomainHigh, left, right, slope, intercept);
            position += 4;
        } else if (opcode == 1) {
            if (position >= length) return -1;
            const std::int64_t x = values[position++];
            if (x < kDomainLow || x > kDomainHigh) return -1;
            const std::int64_t answer = tree.minimum_at(1, kDomainLow, kDomainHigh, x);
            ++query_number;
            checksum += query_number * (answer + kChecksumOffset);
        } else {
            return -1;
        }
    }
    return position == length ? checksum : -1;
}
