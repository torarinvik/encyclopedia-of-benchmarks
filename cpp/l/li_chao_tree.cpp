#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::size_t kMaxOperations = 512;
constexpr std::size_t kMaxNodes = kMaxOperations * 24 + 1;
constexpr std::int64_t kDomainLow = -1'000'000;
constexpr std::int64_t kDomainHigh = 1'000'000;
constexpr std::int64_t kCoefficientLimit = 1'000;
constexpr std::int64_t kChecksumOffset = 1'000'001'001;

struct Node {
    std::int64_t slope = 0;
    std::int64_t intercept = 0;
    int left = -1;
    int right = -1;
    bool occupied = false;
};

struct LiChaoTree {
    std::array<Node, kMaxNodes> nodes{};
    std::size_t used = 0;
    int root = -1;

    static std::int64_t evaluate(std::int64_t slope, std::int64_t intercept, std::int64_t x)
    {
        return slope * x + intercept;
    }

    int allocate()
    {
        if (used == kMaxNodes) return -1;
        return static_cast<int>(used++);
    }

    bool insert_at(int id, std::int64_t low, std::int64_t high,
                   std::int64_t slope, std::int64_t intercept)
    {
        Node &node = nodes[static_cast<std::size_t>(id)];
        if (!node.occupied) {
            node.slope = slope;
            node.intercept = intercept;
            node.occupied = true;
            return true;
        }

        const std::int64_t middle = low + (high - low) / 2;
        if (evaluate(slope, intercept, middle) < evaluate(node.slope, node.intercept, middle)) {
            std::swap(slope, node.slope);
            std::swap(intercept, node.intercept);
        }
        if (low == high) return true;

        int *child_slot = nullptr;
        std::int64_t next_low = low;
        std::int64_t next_high = middle;
        if (evaluate(slope, intercept, low) < evaluate(node.slope, node.intercept, low)) {
            child_slot = &node.left;
        } else if (evaluate(slope, intercept, high) < evaluate(node.slope, node.intercept, high)) {
            child_slot = &node.right;
            next_low = middle + 1;
            next_high = high;
        } else {
            return true;
        }

        if (*child_slot < 0) {
            const int child = allocate();
            if (child < 0) return false;
            *child_slot = child;
        }
        return insert_at(*child_slot, next_low, next_high, slope, intercept);
    }

    bool add(std::int64_t slope, std::int64_t intercept)
    {
        if (root < 0) {
            root = allocate();
            if (root < 0) return false;
        }
        return insert_at(root, kDomainLow, kDomainHigh, slope, intercept);
    }

    std::int64_t minimum_at(int id, std::int64_t low, std::int64_t high, std::int64_t x) const
    {
        const Node &node = nodes[static_cast<std::size_t>(id)];
        std::int64_t best = evaluate(node.slope, node.intercept, x);
        if (low == high) return best;
        const std::int64_t middle = low + (high - low) / 2;
        const bool go_left = x <= middle;
        const int child = go_left ? node.left : node.right;
        if (child >= 0) {
            const std::int64_t nested = minimum_at(child,
                go_left ? low : middle + 1, go_left ? middle : high, x);
            if (nested < best) best = nested;
        }
        return best;
    }
};
} // namespace

extern "C" std::int64_t li_chao_tree(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length < 1 || length > 1 + 3 * kMaxOperations) return -1;
    if (values[0] < 0 || values[0] > static_cast<std::int64_t>(kMaxOperations)) return -1;
    const std::size_t operation_count = static_cast<std::size_t>(values[0]);
    if (length != 1 + 3 * operation_count) return -1;

    LiChaoTree tree;
    std::size_t inserted = 0;
    std::size_t query_number = 0;
    std::int64_t checksum = 0;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const std::size_t offset = 1 + 3 * operation;
        const std::int64_t opcode = values[offset];
        const std::int64_t first = values[offset + 1];
        const std::int64_t second = values[offset + 2];
        if (opcode == 0) {
            if (first < -kCoefficientLimit || first > kCoefficientLimit
                || second < -kCoefficientLimit || second > kCoefficientLimit
                || !tree.add(first, second)) return -1;
            ++inserted;
        } else if (opcode == 1) {
            if (first < kDomainLow || first > kDomainHigh || second != 0 || inserted == 0) return -1;
            const std::int64_t answer = tree.minimum_at(tree.root, kDomainLow, kDomainHigh, first);
            ++query_number;
            checksum += static_cast<std::int64_t>(query_number) * (answer + kChecksumOffset);
        } else {
            return -1;
        }
    }
    return checksum;
}
