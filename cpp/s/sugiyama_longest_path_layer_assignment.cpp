#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 32;
constexpr std::size_t kMaxM = 128;
constexpr std::size_t kMaxInput = 258;

void put_i64_le(std::uint8_t* output, std::size_t word, std::uint64_t value) noexcept {
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[word * 8 + byte] = static_cast<std::uint8_t>(value >> (8 * byte));
    }
}
}

extern "C" std::int64_t sugiyama_longest_path_layer_assignment(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > kMaxInput + 1) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(kMaxN) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(kMaxM)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto m = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * m) return -1;

    std::array<std::uint32_t, kMaxN> adjacency{};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto source = input[2 + 2 * edge], target = input[3 + 2 * edge];
        if (source < 0 || source >= static_cast<std::int64_t>(n) ||
            target < 0 || target >= static_cast<std::int64_t>(n)) return -1;
        const auto bit = std::uint32_t{1} << static_cast<unsigned>(target);
        if ((adjacency[static_cast<std::size_t>(source)] & bit) != 0) return -1;
        adjacency[static_cast<std::size_t>(source)] |= bit;
    }

    std::array<bool, kMaxN> removed{};
    std::array<std::size_t, kMaxN> sink_depth{};
    std::size_t remaining = n, depth = 0;
    while (remaining > 0) {
        std::array<bool, kMaxN> sinks{};
        std::size_t sink_count = 0;
        for (std::size_t vertex = 0; vertex < n; ++vertex) {
            if (removed[vertex]) continue;
            bool has_remaining_successor = false;
            for (std::size_t target = 0; target < n; ++target) {
                if (!removed[target] && (adjacency[vertex] & (std::uint32_t{1} << target)) != 0) {
                    has_remaining_successor = true;
                    break;
                }
            }
            if (!has_remaining_successor) { sinks[vertex] = true; ++sink_count; }
        }
        if (sink_count == 0) return -1;
        for (std::size_t vertex = 0; vertex < n; ++vertex) {
            if (sinks[vertex]) { removed[vertex] = true; sink_depth[vertex] = depth; }
        }
        remaining -= sink_count;
        ++depth;
    }

    const std::size_t output_bytes = 8 * (n + 1);
    if (output == nullptr || capacity < output_bytes) return -2;
    put_i64_le(output, 0, static_cast<std::uint64_t>(depth));
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        put_i64_le(output, vertex + 1,
                   static_cast<std::uint64_t>(depth - 1 - sink_depth[vertex]));
    }
    return static_cast<std::int64_t>(output_bytes);
}
