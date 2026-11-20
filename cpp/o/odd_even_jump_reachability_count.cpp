#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 64;
constexpr std::size_t MAX_PARSEABLE = 66;

bool comes_before(const std::int64_t *values, std::size_t left,
                  std::size_t right, bool descending) {
    if (values[left] != values[right])
        return descending ? values[left] > values[right] : values[left] < values[right];
    return left < right;
}

void build_successors(const std::int64_t *values, std::size_t n, bool descending,
                      std::array<std::int64_t, MAX_N> &target) {
    std::array<std::size_t, MAX_N> order{};
    std::array<std::size_t, MAX_N> stack{};
    for (std::size_t i = 0; i < n; ++i) {
        order[i] = i;
        target[i] = -1;
    }
    for (std::size_t i = 1; i < n; ++i) {
        const auto key = order[i];
        std::size_t position = i;
        while (position > 0 && comes_before(values, key, order[position - 1], descending)) {
            order[position] = order[position - 1];
            --position;
        }
        order[position] = key;
    }
    std::size_t stack_size = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const auto index = order[i];
        while (stack_size > 0 && stack[stack_size - 1] < index)
            target[stack[--stack_size]] = static_cast<std::int64_t>(index);
        stack[stack_size++] = index;
    }
}
} // namespace

extern "C" std::int64_t odd_even_jump_reachability_count(
    const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > MAX_PARSEABLE) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(MAX_N)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != n + 1) return -1;
    const auto *values = input + 1;
    for (std::size_t i = 0; i < n; ++i)
        if (values[i] < -1000000 || values[i] > 1000000) return -1;

    std::array<std::int64_t, MAX_N> odd_next{}, even_next{};
    std::array<bool, MAX_N> odd{}, even{};
    build_successors(values, n, false, odd_next);
    build_successors(values, n, true, even_next);
    odd[n - 1] = even[n - 1] = true;
    for (std::size_t index = n - 1; index > 0;) {
        --index;
        if (odd_next[index] >= 0) odd[index] = even[static_cast<std::size_t>(odd_next[index])];
        if (even_next[index] >= 0) even[index] = odd[static_cast<std::size_t>(even_next[index])];
    }
    std::int64_t count = 0;
    for (std::size_t i = 0; i < n; ++i) count += odd[i] ? 1 : 0;
    return count;
}
