// Minimum digit sum of a 0/1 multiple, by 0-1 BFS on residues.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kDequeCapacity = 512;

std::int64_t minimum_digit_sum(std::int64_t n) noexcept {
    std::int64_t distance[16];
    std::int64_t deque[kDequeCapacity]{};
    for (std::size_t i = 0; i < static_cast<std::size_t>(n); ++i) distance[i] = 1000;
    std::size_t head = 0, tail = 0, count = 0;
    const auto start = static_cast<std::size_t>(1 % n);
    distance[start] = 1;
    deque[tail] = static_cast<std::int64_t>(start);
    tail = (tail + 1) % kDequeCapacity;
    ++count;
    while (count != 0) {
        const auto residue = static_cast<std::size_t>(deque[head]);
        head = (head + 1) % kDequeCapacity;
        --count;
        const auto zero_next = (static_cast<std::int64_t>(residue) * 10) % n;
        if (distance[static_cast<std::size_t>(zero_next)] > distance[residue]) {
            distance[static_cast<std::size_t>(zero_next)] = distance[residue];
            head = (head + kDequeCapacity - 1) % kDequeCapacity;
            deque[head] = zero_next;
            ++count;
        }
        const auto one_next = (zero_next + 1) % n;
        if (distance[static_cast<std::size_t>(one_next)] > distance[residue] + 1) {
            distance[static_cast<std::size_t>(one_next)] = distance[residue] + 1;
            deque[tail] = one_next;
            tail = (tail + 1) % kDequeCapacity;
            ++count;
        }
    }
    return distance[0];
}
} // namespace

extern "C" std::int64_t shortest_path_modulo_small_multiple(
    const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length != 1) return -1;
    const auto n = input[0];
    if (n < 1 || n > 16) return -1;
    return minimum_digit_sum(n);
}
