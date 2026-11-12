#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxOperations = 64;
constexpr std::int64_t kModulus = 998'244'353;
constexpr std::size_t kTreeBase = 128;
constexpr std::size_t kTreeNodes = 256;
constexpr std::size_t kMaxInputLength = 1 + 3 * kMaxOperations;

struct Affine { std::int64_t a = 1; std::int64_t b = 0; };

Affine compose(Affine first, Affine second)
{
    return {(second.a * first.a) % kModulus,
            (second.a * first.b + second.b) % kModulus};
}

struct AggregateDeque {
    std::array<Affine, kTreeNodes> tree{};
    std::size_t head = 64;
    std::size_t tail = 64;

    AggregateDeque()
    {
        tree.fill(Affine{});
    }

    void update(std::size_t position, Affine value)
    {
        std::size_t node = kTreeBase + position;
        tree[node] = value;
        while (node > 1) {
            node >>= 1;
            tree[node] = compose(tree[node * 2], tree[node * 2 + 1]);
        }
    }
};
} // namespace

extern "C" std::int64_t deque_operate_all_composite(const std::int64_t *values,
                                                       std::size_t length)
{
    if (values == nullptr || length < 1 || length > kMaxInputLength) return -1;
    if (values[0] < 0 || values[0] > kMaxOperations) return -1;
    const std::size_t operation_count = static_cast<std::size_t>(values[0]);
    AggregateDeque deque;
    std::size_t position = 1;
    std::int64_t checksum = 0;
    std::int64_t query_number = 0;

    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        if (position >= length) return -1;
        const std::int64_t opcode = values[position++];
        if (opcode == 0 || opcode == 1) {
            if (length - position < 2) return -1;
            const std::int64_t a = values[position++];
            const std::int64_t b = values[position++];
            if (a < 1 || a >= kModulus || b < 0 || b >= kModulus) return -1;
            const Affine function{a, b};
            if (opcode == 0) {
                if (deque.head == 0) return -1;
                deque.update(--deque.head, function);
            } else {
                if (deque.tail == kTreeBase) return -1;
                deque.update(deque.tail++, function);
            }
        } else if (opcode == 2 || opcode == 3) {
            if (deque.head == deque.tail) return -1;
            if (opcode == 2) deque.update(deque.head++, Affine{});
            else deque.update(--deque.tail, Affine{});
        } else if (opcode == 4) {
            if (position >= length) return -1;
            const std::int64_t x = values[position++];
            if (x < 0 || x >= kModulus) return -1;
            const Affine function = deque.tree[1];
            const std::int64_t answer = (function.a * x + function.b) % kModulus;
            ++query_number;
            checksum += query_number * (answer + 1);
        } else {
            return -1;
        }
    }
    return position == length ? checksum : -1;
}
