#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_values = 256;
constexpr std::size_t max_input_length = 258;

std::size_t distinguished_ancestor(std::size_t node,
                                   const bool reverse[max_values]) noexcept {
    while ((node & 1U) == static_cast<std::size_t>(reverse[node / 2])) node /= 2;
    return node / 2;
}

void join(std::int64_t values[max_values], bool reverse[max_values],
          std::size_t ancestor, std::size_t node) noexcept {
    if (values[ancestor] < values[node]) {
        const std::int64_t temporary = values[ancestor];
        values[ancestor] = values[node];
        values[node] = temporary;
        reverse[node] = !reverse[node];
    }
}

void sift_down(std::int64_t values[max_values], bool reverse[max_values],
               std::size_t active_size) noexcept {
    std::size_t node = 1U - static_cast<std::size_t>(reverse[0]);
    if (node >= active_size) return;
    while (2 * node + static_cast<std::size_t>(reverse[node]) < active_size)
        node = 2 * node + static_cast<std::size_t>(reverse[node]);
    while (node != 0) {
        join(values, reverse, 0, node);
        node /= 2;
    }
}
} // namespace

extern "C" std::int64_t weak_heapsort(const std::int64_t *input,
                                       std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    const std::int64_t raw_count = input[0];
    if (raw_count < 0 || raw_count > static_cast<std::int64_t>(max_values)) return -1;
    const std::size_t count = static_cast<std::size_t>(raw_count);
    if (length != count + 1) return -1;

    std::int64_t values[max_values]{};
    bool reverse[max_values]{};
    for (std::size_t i = 0; i < count; ++i) {
        const std::int64_t value = input[i + 1];
        if (value < -1000 || value > 1000) return -1;
        values[i] = value;
    }

    for (std::size_t next = count; next > 1; --next) {
        const std::size_t node = next - 1;
        const std::size_t ancestor = distinguished_ancestor(node, reverse);
        join(values, reverse, ancestor, node);
    }
    for (std::size_t end = count; end > 1; --end) {
        const std::int64_t temporary = values[0];
        values[0] = values[end - 1];
        values[end - 1] = temporary;
        sift_down(values, reverse, end - 1);
    }

    std::int64_t checksum = 0;
    for (std::size_t i = 0; i < count; ++i)
        checksum += static_cast<std::int64_t>(i + 1) * (values[i] + 1001);
    return checksum;
}
