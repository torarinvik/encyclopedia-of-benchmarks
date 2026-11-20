#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMax = 64;
constexpr std::size_t kCells = kMax * kMax;

void add_color(std::size_t map, std::size_t color, std::int64_t amount,
               const std::array<std::int64_t, kMax>& labels,
               std::array<std::int64_t, kCells>& frequencies,
               std::array<std::size_t, kCells>& keys,
               std::array<std::size_t, kMax>& lengths,
               std::array<std::int64_t, kMax>& maximum,
               std::array<std::int64_t, kMax>& sum) {
    const auto cell = map * kMax + color;
    const auto old = frequencies[cell];
    if (old == 0) keys[map * kMax + lengths[map]++] = color;
    if (old > 0 && old == maximum[map]) sum[map] -= labels[color];
    const auto updated = old + amount;
    if (updated > maximum[map]) {
        maximum[map] = updated;
        sum[map] = labels[color];
    } else if (updated == maximum[map]) {
        sum[map] += labels[color];
    }
    frequencies[cell] = updated;
}

void put_i64(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}  // namespace

extern "C" std::int64_t small_to_large_subtree_color_mode_sum(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) {
    if (input == nullptr || length < 2 || length > 129) return -1;
    const auto n_value = input[0];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(kMax) ||
        length != static_cast<std::size_t>(2 * n_value)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    std::array<std::size_t, kMax> parent{};
    for (std::size_t vertex = 1; vertex < n; ++vertex) {
        const auto p = input[vertex];
        if (p < 0 || p >= static_cast<std::int64_t>(vertex)) return -1;
        parent[vertex] = static_cast<std::size_t>(p);
    }
    std::array<std::int64_t, kMax> labels{};
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        const auto color = input[n + vertex];
        if (color < -1000 || color > 1000) return -1;
        labels[vertex] = color;
    }
    std::sort(labels.begin(), labels.begin() + static_cast<std::ptrdiff_t>(n));
    std::array<std::int64_t, kMax> unique{};
    std::size_t distinct = 0;
    for (std::size_t i = 0; i < n; ++i)
        if (distinct == 0 || unique[distinct - 1] != labels[i]) unique[distinct++] = labels[i];
    std::array<std::size_t, kMax> color_index{};
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        std::size_t index = 0;
        while (unique[index] != input[n + vertex]) ++index;
        color_index[vertex] = index;
    }
    if (output == nullptr || capacity < 8 * n) return -2;

    std::array<std::int64_t, kCells> frequencies{};
    std::array<std::size_t, kCells> keys{};
    std::array<std::size_t, kMax> lengths{}, map_id{};
    std::array<std::int64_t, kMax> maximum{}, mode_sum{}, answers{};
    for (std::size_t vertex = n; vertex-- > 0;) {
        std::size_t largest = n;
        for (std::size_t child = vertex + 1; child < n; ++child)
            if (parent[child] == vertex &&
                (largest == n || lengths[map_id[child]] > lengths[map_id[largest]])) largest = child;
        const auto map = largest == n ? vertex : map_id[largest];
        for (std::size_t child = vertex + 1; child < n; ++child) {
            if (parent[child] != vertex || child == largest) continue;
            const auto small = map_id[child];
            for (std::size_t i = 0; i < lengths[small]; ++i) {
                const auto color = keys[small * kMax + i];
                add_color(map, color, frequencies[small * kMax + color], unique,
                          frequencies, keys, lengths, maximum, mode_sum);
            }
        }
        add_color(map, color_index[vertex], 1, unique, frequencies, keys,
                  lengths, maximum, mode_sum);
        map_id[vertex] = map;
        answers[vertex] = mode_sum[map];
    }
    for (std::size_t vertex = 0; vertex < n; ++vertex) put_i64(output, vertex * 8, answers[vertex]);
    return static_cast<std::int64_t>(8 * n);
}
