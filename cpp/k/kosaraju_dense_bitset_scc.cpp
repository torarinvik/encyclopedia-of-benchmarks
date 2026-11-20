#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxVertices = 256;
constexpr std::size_t MaxWords = 4;
constexpr std::size_t MaxCells = MaxVertices * MaxWords;
constexpr std::size_t MaxParseableInputLength = 1 + MaxCells + 1;

unsigned lowest_bit_index(std::uint64_t bits) noexcept
{
    unsigned index = 0;
    while ((bits & UINT64_C(1)) == 0) { bits >>= 1; ++index; }
    return index;
}

void write_u16_le(std::uint8_t *output, std::size_t position, std::uint16_t value) noexcept
{
    output[position] = static_cast<std::uint8_t>(value & UINT16_C(0xff));
    output[position + 1] = static_cast<std::uint8_t>(value >> 8);
}
}

extern "C" std::int64_t kosaraju_dense_bitset_scc(const std::int64_t *input, std::size_t length,
                                                    std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || length < 1 || length > MaxParseableInputLength) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(MaxVertices)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const std::size_t words = (n + 63) / 64;
    if (length != 1 + n * words) return -1;

    std::uint64_t adjacency[MaxCells]{}, transpose[MaxCells]{};
    for (std::size_t cell = 0; cell < n * words; ++cell)
        adjacency[cell] = static_cast<std::uint64_t>(input[1 + cell]);
    if ((n & 63u) != 0) {
        const std::uint64_t valid = (UINT64_C(1) << (n & 63u)) - 1;
        for (std::size_t vertex = 0; vertex < n; ++vertex)
            if ((adjacency[vertex * words + words - 1] & ~valid) != 0) return -1;
    }
    for (std::size_t source = 0; source < n; ++source) {
        for (std::size_t word = 0; word < words; ++word) {
            std::uint64_t bits = adjacency[source * words + word];
            while (bits != 0) {
                const unsigned bit = lowest_bit_index(bits);
                const std::size_t target = word * 64 + bit;
                transpose[target * words + source / 64] |= UINT64_C(1) << (source & 63u);
                bits &= bits - 1;
            }
        }
    }

    std::uint64_t unvisited[MaxWords]{};
    for (std::size_t word = 0; word < words; ++word) unvisited[word] = UINT64_MAX;
    if ((n & 63u) != 0) unvisited[words - 1] = (UINT64_C(1) << (n & 63u)) - 1;
    std::uint16_t stack[MaxVertices], next_word[MaxVertices], order[MaxVertices];
    std::size_t order_length = 0;
    for (std::size_t root = 0; root < n; ++root) {
        const std::size_t root_word = root / 64, root_bit = root & 63u;
        if (((unvisited[root_word] >> root_bit) & 1u) == 0) continue;
        unvisited[root_word] &= ~(UINT64_C(1) << root_bit);
        std::size_t stack_length = 1;
        stack[0] = static_cast<std::uint16_t>(root);
        next_word[0] = 0;
        while (stack_length != 0) {
            const std::size_t depth = stack_length - 1;
            const std::size_t vertex = stack[depth];
            bool pushed = false;
            while (next_word[depth] < words) {
                const std::size_t word = next_word[depth];
                const std::uint64_t candidates = adjacency[vertex * words + word] & unvisited[word];
                if (candidates != 0) {
                    const unsigned bit = lowest_bit_index(candidates);
                    const std::size_t neighbor = word * 64 + bit;
                    unvisited[word] &= ~(UINT64_C(1) << bit);
                    stack[stack_length] = static_cast<std::uint16_t>(neighbor);
                    next_word[stack_length] = 0;
                    ++stack_length;
                    pushed = true;
                    break;
                }
                ++next_word[depth];
            }
            if (!pushed && next_word[depth] == words) {
                order[order_length++] = static_cast<std::uint16_t>(vertex);
                --stack_length;
            }
        }
    }

    for (std::size_t word = 0; word < words; ++word) unvisited[word] = UINT64_MAX;
    if ((n & 63u) != 0) unvisited[words - 1] = (UINT64_C(1) << (n & 63u)) - 1;
    std::uint16_t raw_component[MaxVertices];
    std::uint16_t component_count = 0;
    while (order_length != 0) {
        const std::size_t root = order[--order_length];
        const std::size_t root_word = root / 64, root_bit = root & 63u;
        if (((unvisited[root_word] >> root_bit) & 1u) == 0) continue;
        unvisited[root_word] &= ~(UINT64_C(1) << root_bit);
        std::size_t stack_length = 1;
        stack[0] = static_cast<std::uint16_t>(root);
        raw_component[root] = component_count;
        while (stack_length != 0) {
            const std::size_t vertex = stack[--stack_length];
            for (std::size_t word = 0; word < words; ++word) {
                std::uint64_t candidates = transpose[vertex * words + word] & unvisited[word];
                while (candidates != 0) {
                    const unsigned bit = lowest_bit_index(candidates);
                    const std::size_t neighbor = word * 64 + bit;
                    const std::uint64_t selected = UINT64_C(1) << bit;
                    unvisited[word] &= ~selected;
                    candidates &= ~selected;
                    raw_component[neighbor] = component_count;
                    stack[stack_length++] = static_cast<std::uint16_t>(neighbor);
                }
            }
        }
        ++component_count;
    }

    std::uint16_t remap[MaxVertices];
    for (auto &entry : remap) entry = UINT16_MAX;
    std::uint16_t canonical_count = 0;
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        const auto raw = raw_component[vertex];
        if (remap[raw] == UINT16_MAX) remap[raw] = canonical_count++;
    }
    const std::size_t output_length = 2 + 2 * n;
    if (output == nullptr || output_capacity < output_length) return -2;
    write_u16_le(output, 0, canonical_count);
    for (std::size_t vertex = 0; vertex < n; ++vertex)
        write_u16_le(output, 2 + 2 * vertex, remap[raw_component[vertex]]);
    return static_cast<std::int64_t>(output_length);
}
