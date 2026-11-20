#include <cstddef>
#include <cstdint>

namespace {
void store_i64_le(std::uint8_t* output, std::size_t at, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[at + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t hypercube_edge_monotonicity_tester(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) {
    if (input == nullptr || length < 2 || length > 130) return -1;
    const auto n_value = input[0];
    const auto q_value = input[1];
    if (n_value < 1 || n_value > 6 || q_value < 1 || q_value > 32) return -1;
    const auto domain = std::size_t{1} << static_cast<unsigned>(n_value);
    const auto q = static_cast<std::size_t>(q_value);
    if (length != 2 + domain + 2 * q) return -1;
    for (std::size_t vertex = 0; vertex < domain; ++vertex)
        if (input[2 + vertex] != 0 && input[2 + vertex] != 1) return -1;
    const std::size_t tape = 2 + domain;
    for (std::size_t round = 0; round < q; ++round) {
        const auto vertex = input[tape + 2 * round];
        const auto coordinate = input[tape + 2 * round + 1];
        if (vertex < 0 || static_cast<std::uint64_t>(vertex) >= domain ||
            coordinate < 0 || coordinate >= n_value) return -1;
    }
    std::int64_t accepted = 1, rounds = 0;
    for (std::size_t round = 0; round < q; ++round) {
        const auto vertex = static_cast<std::size_t>(input[tape + 2 * round]);
        const auto bit = std::size_t{1} << static_cast<unsigned>(input[tape + 2 * round + 1]);
        const auto lower = vertex & ~bit;
        ++rounds;
        if (input[2 + lower] > input[2 + (lower | bit)]) { accepted = 0; break; }
    }
    if (output == nullptr || capacity < 24) return -2;
    store_i64_le(output, 0, accepted);
    store_i64_le(output, 8, rounds);
    store_i64_le(output, 16, 2 * rounds);
    return 24;
}
