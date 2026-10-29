#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxOperations = 64;
constexpr std::int64_t kModulus = 998'244'353;
constexpr std::size_t kMaxInputLength = 1 + 3 * 64;

struct Affine {
    std::int64_t a = 1;
    std::int64_t b = 0;
};

Affine compose(Affine first, Affine second)
{
    return {
        (second.a * first.a) % kModulus,
        (second.a * first.b + second.b) % kModulus,
    };
}

struct AggregateQueue {
    std::array<Affine, 64> back_functions{};
    std::array<Affine, 64> back_aggregates{};
    std::array<Affine, 64> front_aggregates{};
    std::size_t back_size = 0;
    std::size_t front_size = 0;

    void push(std::int64_t a, std::int64_t b)
    {
        const Affine function{a, b};
        back_functions[back_size] = function;
        back_aggregates[back_size] = back_size == 0
            ? function : compose(back_aggregates[back_size - 1], function);
        ++back_size;
    }

    void transfer()
    {
        while (back_size > 0) {
            const Affine function = back_functions[--back_size];
            front_aggregates[front_size] = front_size == 0
                ? function : compose(function, front_aggregates[front_size - 1]);
            ++front_size;
        }
    }

    bool pop()
    {
        if (front_size == 0) transfer();
        if (front_size == 0) return false;
        --front_size;
        return true;
    }

    Affine aggregate() const
    {
        Affine result{};
        if (front_size > 0) result = front_aggregates[front_size - 1];
        if (back_size > 0)
            result = front_size > 0 ? compose(result, back_aggregates[back_size - 1])
                                    : back_aggregates[back_size - 1];
        return result;
    }
};
} // namespace

extern "C" std::int64_t queue_operate_all_composite(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length < 1 || length > kMaxInputLength) return -1;
    if (values[0] < 0 || values[0] > kMaxOperations) return -1;
    const std::size_t operation_count = static_cast<std::size_t>(values[0]);
    AggregateQueue queue;
    std::size_t position = 1;
    std::int64_t checksum = 0;
    std::int64_t query_number = 0;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        if (position >= length) return -1;
        const std::int64_t opcode = values[position++];
        if (opcode == 0) {
            if (length - position < 2) return -1;
            const std::int64_t a = values[position++];
            const std::int64_t b = values[position++];
            if (a < 1 || a >= kModulus || b < 0 || b >= kModulus) return -1;
            queue.push(a, b);
        } else if (opcode == 1) {
            if (!queue.pop()) return -1;
        } else if (opcode == 2) {
            if (position >= length) return -1;
            const std::int64_t x = values[position++];
            if (x < 0 || x >= kModulus) return -1;
            const Affine function = queue.aggregate();
            const std::int64_t answer = (function.a * x + function.b) % kModulus;
            ++query_number;
            checksum += query_number * (answer + 1);
        } else {
            return -1;
        }
    }
    return position == length ? checksum : -1;
}
