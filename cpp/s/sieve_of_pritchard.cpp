/* Count primes through limit with Pritchard's dynamic wheel sieve. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int32_t max_limit = 1024;
constexpr std::size_t link_count = 1026;
}

extern "C" std::int64_t sieve_of_pritchard(const std::int64_t *input,
                                             std::size_t length) noexcept
{
    if (input == nullptr || length < 1 || length > 2) return -1;
    if (length != 1 || input[0] < 2 || input[0] > max_limit) return -1;

    const auto limit = static_cast<std::int32_t>(input[0]);
    const std::int32_t sentinel = limit + 1;
    std::array<std::int32_t, link_count> next_node{};
    std::array<std::int32_t, link_count> previous{};
    next_node[1] = sentinel;
    next_node[static_cast<std::size_t>(sentinel)] = sentinel;
    previous[static_cast<std::size_t>(sentinel)] = 1;

    std::int32_t wheel_length = 2;
    std::int32_t prime = 3;
    std::int64_t prime_count = 1;
    while (prime * prime <= limit) {
        if (wheel_length < limit) {
            const std::int32_t product = prime * wheel_length;
            const std::int32_t target = product < limit ? product : limit;
            std::int32_t wheel_value = 1;
            std::int32_t candidate = wheel_length + 1;
            while (candidate <= target) {
                const std::int32_t tail = previous[static_cast<std::size_t>(sentinel)];
                next_node[static_cast<std::size_t>(tail)] = candidate;
                previous[static_cast<std::size_t>(candidate)] = tail;
                next_node[static_cast<std::size_t>(candidate)] = sentinel;
                previous[static_cast<std::size_t>(sentinel)] = candidate;
                wheel_value = next_node[static_cast<std::size_t>(wheel_value)];
                candidate = wheel_length + wheel_value;
            }
            wheel_length = target;
        }

        std::int32_t wheel_value = prime;
        while (prime * wheel_value <= wheel_length)
            wheel_value = next_node[static_cast<std::size_t>(wheel_value)];
        while (wheel_value > 1) {
            wheel_value = previous[static_cast<std::size_t>(wheel_value)];
            const std::int32_t removed = prime * wheel_value;
            const std::int32_t left = previous[static_cast<std::size_t>(removed)];
            const std::int32_t right = next_node[static_cast<std::size_t>(removed)];
            next_node[static_cast<std::size_t>(left)] = right;
            previous[static_cast<std::size_t>(right)] = left;
        }
        ++prime_count;
        prime = next_node[1];
    }

    if (wheel_length < limit) {
        std::int32_t wheel_value = 1;
        std::int32_t candidate = wheel_length + 1;
        while (candidate <= limit) {
            const std::int32_t tail = previous[static_cast<std::size_t>(sentinel)];
            next_node[static_cast<std::size_t>(tail)] = candidate;
            previous[static_cast<std::size_t>(candidate)] = tail;
            next_node[static_cast<std::size_t>(candidate)] = sentinel;
            previous[static_cast<std::size_t>(sentinel)] = candidate;
            wheel_value = next_node[static_cast<std::size_t>(wheel_value)];
            candidate = wheel_length + wheel_value;
        }
        wheel_length = limit;
    }

    std::int64_t remaining = 0;
    std::int32_t value = next_node[1];
    while (value != sentinel) {
        ++remaining;
        value = next_node[static_cast<std::size_t>(value)];
    }
    return prime_count + remaining;
}
