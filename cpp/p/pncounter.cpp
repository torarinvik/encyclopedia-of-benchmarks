/* Bounded source-faithful trace of the pinned Java PN counter. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxNodes = 16;
constexpr std::size_t kMaxOperations = 64;
constexpr std::size_t kMaxInputLength = 5 + kMaxOperations;
constexpr std::size_t kMaxOutputWords = 2 * kMaxOperations;
constexpr std::array<std::array<std::size_t, 2>, 6> kPairs{{
    {{0, 1}}, {{0, 2}}, {{1, 0}}, {{1, 2}}, {{2, 0}}, {{2, 1}}
}};

void append(std::array<std::int64_t, kMaxOutputWords>& words,
            std::size_t& count, std::int64_t value) noexcept {
    words[count++] = value;
}

void put_i64_le(std::uint8_t* output, std::size_t offset,
                std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t pncounter(const std::int64_t* input, std::size_t length,
                                   std::uint8_t* output,
                                   std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 5 || length > kMaxInputLength) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxNodes) ||
        input[4] < 0 || input[4] > static_cast<std::int64_t>(kMaxOperations)) return -1;

    const auto node_count = static_cast<std::size_t>(input[0]);
    std::array<std::size_t, 3> ids{};
    for (std::size_t counter = 0; counter < ids.size(); ++counter) {
        if (input[1 + counter] < 0 || input[1 + counter] >= input[0]) return -1;
        ids[counter] = static_cast<std::size_t>(input[1 + counter]);
    }
    const auto operation_count = static_cast<std::size_t>(input[4]);
    if (length != 5 + operation_count) return -1;

    std::array<std::array<std::int64_t, kMaxNodes>, 3> positive{};
    std::array<std::array<std::int64_t, kMaxNodes>, 3> negative{};
    std::array<std::int64_t, kMaxOutputWords> words{};
    std::size_t word_count = 0;
    std::size_t position = 5;

    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const auto opcode = input[position++];
        if (opcode < 0 || opcode > 20) return -1;
        if (opcode < 6) {
            const auto counter = static_cast<std::size_t>(opcode / 2);
            if ((opcode & 1) == 0) ++positive[counter][ids[counter]];
            else ++negative[counter][ids[counter]];
            append(words, word_count, opcode);
        } else if (opcode < 9) {
            const auto counter = static_cast<std::size_t>(opcode - 6);
            std::int64_t value = 0;
            for (std::size_t node = 0; node < node_count; ++node)
                value += positive[counter][node] - negative[counter][node];
            append(words, word_count, opcode);
            append(words, word_count, value);
        } else if (opcode < 15) {
            const auto pair = kPairs[static_cast<std::size_t>(opcode - 9)];
            const auto target = pair[0];
            const auto source = pair[1];
            for (std::size_t node = 0; node < node_count; ++node) {
                if (positive[target][node] < positive[source][node])
                    positive[target][node] = positive[source][node];
                if (negative[target][node] < negative[source][node])
                    negative[target][node] = negative[source][node];
            }
            append(words, word_count, opcode);
        } else {
            const auto pair = kPairs[static_cast<std::size_t>(opcode - 15)];
            const auto left = pair[0];
            const auto right = pair[1];
            bool result = true;
            for (std::size_t node = 0; node < node_count; ++node) {
                if (positive[left][node] > positive[right][node] &&
                    negative[left][node] > negative[right][node]) {
                    result = false;
                    break;
                }
            }
            append(words, word_count, opcode);
            append(words, word_count, result ? 1 : 0);
        }
    }

    const auto output_length = word_count * 8;
    if (output == nullptr || output_capacity < output_length) return -2;
    for (std::size_t i = 0; i < word_count; ++i)
        put_i64_le(output, i * 8, words[i]);
    return static_cast<std::int64_t>(output_length);
}
