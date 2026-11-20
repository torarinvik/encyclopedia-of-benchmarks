#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 8, max_input = 203, max_output = 88;
std::size_t ceil_log2(std::size_t value) {
    std::size_t exponent = 0, power = 1;
    while (power < value) { power <<= 1; ++exponent; }
    return exponent;
}
void put64(std::uint8_t *out, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) { out[offset + byte] = static_cast<std::uint8_t>(bits & 255U); bits >>= 8; }
}
}

extern "C" std::int64_t radio_network_bgi_broadcast(const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 3 || length > max_input) return -1;
    const auto n64 = input[0], source64 = input[1], delta64 = input[2];
    if (n64 < 2 || n64 > 8 || source64 < 0 || source64 >= n64 || delta64 < 2 || delta64 > 8) return -1;
    const auto n = static_cast<std::size_t>(n64), source = static_cast<std::size_t>(source64), delta = static_cast<std::size_t>(delta64);
    const std::size_t k = 2 * ceil_log2(delta), t = ceil_log2(2 * n), tape_at = 3 + n, tape_count = n * t * k;
    if (length != tape_at + tape_count) return -1;
    const auto full = (std::uint64_t{1} << n) - 1U;
    std::array<std::uint64_t, max_n> adjacency{};
    for (std::size_t v = 0; v < n; ++v) {
        const auto raw = input[3 + v];
        if (raw < 0 || (static_cast<std::uint64_t>(raw) & ~full) != 0 || (static_cast<std::uint64_t>(raw) & (std::uint64_t{1} << v)) != 0) return -1;
        adjacency[v] = static_cast<std::uint64_t>(raw);
        std::size_t degree = 0;
        for (std::size_t u = 0; u < n; ++u) degree += (adjacency[v] >> u) & 1U;
        if (degree > delta) return -1;
    }
    for (std::size_t u = 0; u < n; ++u) for (std::size_t v = 0; v < n; ++v)
        if (((adjacency[u] >> v) & 1U) != ((adjacency[v] >> u) & 1U)) return -1;
    for (std::size_t i = 0; i < tape_count; ++i) if (input[tape_at + i] != 0 && input[tape_at + i] != 1) return -1;
    const std::size_t output_bytes = 8 * (n + 3);
    if (output == nullptr || capacity < output_bytes) return -2;

    std::array<bool, max_n> informed{}, active{}, newly{};
    std::array<std::size_t, max_n> calls{};
    std::array<std::int64_t, max_n> first_slot{};
    first_slot.fill(-1); informed[source] = true; first_slot[source] = 0;
    std::int64_t transmissions = 0, phases = 0;
    for (std::size_t phase = 0; phase < n * t; ++phase) {
        std::size_t starters = 0;
        for (std::size_t v = 0; v < n; ++v) { active[v] = informed[v] && calls[v] < t; newly[v] = false; starters += active[v]; }
        if (starters == 0) break;
        for (std::size_t slot = 0; slot < k; ++slot) {
            for (std::size_t sender = 0; sender < n; ++sender) if (active[sender]) ++transmissions;
            for (std::size_t receiver = 0; receiver < n; ++receiver) {
                if (informed[receiver] || newly[receiver]) continue;
                std::size_t sender_count = 0;
                for (std::size_t sender = 0; sender < n; ++sender)
                    if (active[sender] && ((adjacency[sender] >> receiver) & 1U)) ++sender_count;
                if (sender_count == 1) { newly[receiver] = true; first_slot[receiver] = static_cast<std::int64_t>(phase * k + slot); }
            }
            for (std::size_t sender = 0; sender < n; ++sender) if (active[sender]) {
                const auto at = tape_at + (sender * t + calls[sender]) * k + slot;
                if (slot + 1 == k || input[at] == 0) active[sender] = false;
            }
        }
        for (std::size_t v = 0; v < n; ++v) {
            if (informed[v] && calls[v] < t) ++calls[v];
            if (newly[v]) informed[v] = true;
        }
        phases = static_cast<std::int64_t>(phase + 1);
    }
    std::array<std::uint8_t, max_output> staged{};
    put64(staged.data(), 0, n64); put64(staged.data(), 8, phases); put64(staged.data(), 16, transmissions);
    for (std::size_t v = 0; v < n; ++v) put64(staged.data(), 24 + 8 * v, first_slot[v]);
    for (std::size_t i = 0; i < output_bytes; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(output_bytes);
}
