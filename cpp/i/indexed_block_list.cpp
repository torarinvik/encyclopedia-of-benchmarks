#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t B = 4, MAX_INITIAL = 16, MAX_OPS = 64, MAX_INSERTS = 32;
constexpr std::size_t MAX_ACCESSES = 32, MAX_NODES = 16, MAX_ITEMS = 48, MAX_PARSEABLE = 179;

bool valid_input(const std::int64_t *input, std::size_t length, std::size_t &accesses) {
    if (input == nullptr || length < 2 || length > MAX_PARSEABLE || input[0] < 0 || input[0] > static_cast<std::int64_t>(MAX_INITIAL)) return false;
    const auto initial = static_cast<std::size_t>(input[0]);
    if (length < initial + 2) return false;
    for (std::size_t i = 0; i < initial; ++i) if (input[1 + i] < -1'000'000 || input[1 + i] > 1'000'000) return false;
    const auto raw_ops = input[1 + initial];
    if (raw_ops < 0 || raw_ops > static_cast<std::int64_t>(MAX_OPS)) return false;
    std::size_t cursor = initial + 2, size = initial, inserts = 0;
    accesses = 0;
    for (std::size_t op = 0; op < static_cast<std::size_t>(raw_ops); ++op) {
        if (cursor >= length) return false;
        if (input[cursor] == 0) {
            if (cursor + 3 > length) return false;
            const auto index = input[cursor + 1], value = input[cursor + 2];
            if (index < 0 || static_cast<std::uint64_t>(index) > size || value < -1'000'000 || value > 1'000'000 || ++inserts > MAX_INSERTS) return false;
            ++size; cursor += 3;
        } else if (input[cursor] == 1) {
            if (cursor + 2 > length) return false;
            const auto index = input[cursor + 1];
            if (index < 0 || static_cast<std::uint64_t>(index) >= size || ++accesses > MAX_ACCESSES) return false;
            cursor += 2;
        } else return false;
    }
    return cursor == length && size <= MAX_ITEMS;
}

using Blocks = std::array<std::array<std::int64_t, 2 * B + 1>, MAX_NODES>;
using Sizes = std::array<std::size_t, MAX_NODES>;
using Links = std::array<int, MAX_NODES>;

void insert(Blocks &blocks, Sizes &sizes, Links &next, std::size_t &node_count, std::size_t index, std::int64_t value) {
    int node = 0;
    std::size_t offset = 0;
    while (next[static_cast<std::size_t>(node)] >= 0 && index > offset + sizes[static_cast<std::size_t>(node)]) {
        offset += sizes[static_cast<std::size_t>(node)]; node = next[static_cast<std::size_t>(node)];
    }
    const auto n = static_cast<std::size_t>(node), local = index - offset;
    for (std::size_t j = sizes[n]; j > local; --j) blocks[n][j] = blocks[n][j - 1];
    blocks[n][local] = value; ++sizes[n];
    if (sizes[n] > 2 * B) {
        const auto fresh = node_count++;
        const auto first_moved = sizes[n] - B;
        for (std::size_t j = 0; j < B; ++j) blocks[fresh][j] = blocks[n][first_moved + j];
        sizes[fresh] = B; sizes[n] -= B;
        next[fresh] = next[n]; next[n] = static_cast<int>(fresh);
    }
}

std::int64_t get(const Blocks &blocks, const Sizes &sizes, const Links &next, std::size_t index) {
    int node = 0; std::size_t offset = 0;
    while (index >= offset + sizes[static_cast<std::size_t>(node)]) {
        offset += sizes[static_cast<std::size_t>(node)]; node = next[static_cast<std::size_t>(node)];
    }
    return blocks[static_cast<std::size_t>(node)][index - offset];
}
}

extern "C" std::int64_t indexed_block_list(const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    std::size_t access_count = 0;
    if (!valid_input(input, length, access_count)) return -1;
    if (access_count == 0) return 0;
    const auto required = 8 * access_count;
    if (output == nullptr || capacity < required) return -2;
    Blocks blocks{}; Sizes sizes{}; Links next{}; next.fill(-1); std::size_t node_count = 1;
    const auto initial = static_cast<std::size_t>(input[0]);
    for (std::size_t i = 0; i < initial; ++i) insert(blocks, sizes, next, node_count, i, input[1 + i]);
    std::array<std::int64_t, MAX_ACCESSES> answers{};
    std::size_t answer_count = 0, cursor = initial + 2;
    const auto operations = static_cast<std::size_t>(input[1 + initial]);
    for (std::size_t op = 0; op < operations; ++op) {
        const auto opcode = input[cursor]; const auto index = static_cast<std::size_t>(input[cursor + 1]);
        if (opcode == 0) { insert(blocks, sizes, next, node_count, index, input[cursor + 2]); cursor += 3; }
        else { answers[answer_count++] = get(blocks, sizes, next, index); cursor += 2; }
    }
    for (std::size_t i = 0; i < answer_count; ++i) {
        const auto bits = static_cast<std::uint64_t>(answers[i]);
        for (std::size_t byte = 0; byte < 8; ++byte) output[8 * i + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    }
    return static_cast<std::int64_t>(required);
}
