/* Bounded clean-room connected/co-connected cograph cotree profile. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t ct_n = 12;
constexpr std::size_t ct_m = 66;
constexpr std::size_t ct_parseable = 135;
constexpr std::size_t ct_output = 47;
using Mask = std::uint16_t;
using Adjacency = std::array<Mask, ct_n>;

int components(Mask mask, const Adjacency& adjacency, bool complement,
               std::array<Mask, ct_n>& parts) {
    Mask remaining = mask;
    int count = 0;
    for (int root = 0; root < static_cast<int>(ct_n); ++root) {
        const Mask root_bit = static_cast<Mask>(1u << root);
        if ((remaining & root_bit) == 0) continue;
        Mask reached = root_bit;
        std::array<int, ct_n> queue{};
        int head = 0, tail = 0;
        queue[tail++] = root;
        while (head < tail) {
            const int vertex = queue[head++];
            Mask neighbors = static_cast<Mask>(adjacency[vertex] & mask);
            if (complement)
                neighbors = static_cast<Mask>(mask & static_cast<Mask>(~adjacency[vertex]) &
                                              static_cast<Mask>(~static_cast<Mask>(1u << vertex)));
            Mask fresh = static_cast<Mask>(neighbors & static_cast<Mask>(~reached));
            for (int next = 0; next < static_cast<int>(ct_n); ++next) {
                const Mask bit = static_cast<Mask>(1u << next);
                if (fresh & bit) {
                    fresh = static_cast<Mask>(fresh & static_cast<Mask>(~bit));
                    reached = static_cast<Mask>(reached | bit);
                    queue[tail++] = next;
                }
            }
        }
        parts[count++] = reached;
        remaining = static_cast<Mask>(remaining & static_cast<Mask>(~reached));
    }
    return count;
}

bool emit(Mask mask, const Adjacency& adjacency, std::array<std::uint8_t, ct_output>& out,
          std::size_t& position) {
    if ((mask & static_cast<Mask>(mask - 1u)) == 0) {
        int vertex = 0;
        while ((mask & static_cast<Mask>(1u << vertex)) == 0) ++vertex;
        out[position++] = 0;
        out[position++] = static_cast<std::uint8_t>(vertex);
        return true;
    }
    std::array<Mask, ct_n> parts{};
    int count = components(mask, adjacency, false, parts);
    std::uint8_t kind = 1;
    if (count == 1) {
        count = components(mask, adjacency, true, parts);
        kind = 2;
        if (count <= 1) return false;
    }
    out[position++] = kind;
    out[position++] = static_cast<std::uint8_t>(count);
    for (int i = 0; i < count; ++i)
        if (!emit(parts[static_cast<std::size_t>(i)], adjacency, out, position)) return false;
    return true;
}
} // namespace

extern "C" std::int64_t cograph_cotree_decomposition(const std::int64_t* input,
                                                       std::size_t length,
                                                       std::uint8_t* output,
                                                       std::size_t capacity) {
    if (input == nullptr || length < 2 || length > ct_parseable) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(ct_n) || m64 < 0 ||
        m64 > static_cast<std::int64_t>(ct_m) || m64 > n64 * (n64 - 1) / 2 ||
        length != 2 + 2 * static_cast<std::size_t>(m64)) return -1;
    const auto n = static_cast<int>(n64);
    const auto m = static_cast<int>(m64);
    Adjacency adjacency{};
    for (int edge = 0; edge < m; ++edge) {
        const auto u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || u64 >= n || v64 < 0 || v64 >= n || u64 == v64) return -1;
        const int u = static_cast<int>(u64), v = static_cast<int>(v64);
        const Mask ub = static_cast<Mask>(1u << u), vb = static_cast<Mask>(1u << v);
        if (adjacency[static_cast<std::size_t>(u)] & vb) return -1;
        adjacency[static_cast<std::size_t>(u)] = static_cast<Mask>(adjacency[static_cast<std::size_t>(u)] | vb);
        adjacency[static_cast<std::size_t>(v)] = static_cast<Mask>(adjacency[static_cast<std::size_t>(v)] | ub);
    }
    std::array<std::uint8_t, ct_output> staged{};
    std::size_t output_length = 1;
    if (emit(static_cast<Mask>((1u << n) - 1u), adjacency, staged, output_length)) staged[0] = 1;
    else { staged[0] = 0; output_length = 1; }
    if (output == nullptr || capacity < output_length) return -2;
    for (std::size_t i = 0; i < output_length; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(output_length);
}
