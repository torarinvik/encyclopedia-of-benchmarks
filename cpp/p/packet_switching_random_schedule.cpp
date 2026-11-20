#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_QUEUES = 4, MAX_BUFFER = 4, MAX_SLOTS = 8;
constexpr std::size_t MAX_PARSEABLE_INPUT = 68, MAX_OUTPUT_BYTES = 64;
constexpr std::uint64_t MAX_PRIORITY = UINT64_C(4294967295);
struct Tag { std::int64_t priority = 0; bool marked = false; };
void store_i64_le(std::uint8_t *out, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) out[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t packet_switching_random_schedule(const std::int64_t *input,
        std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 3 || length > MAX_PARSEABLE_INPUT) return -1;
    const auto mv = input[0], bv = input[1], tv = input[2];
    if (mv < 2 || mv > static_cast<std::int64_t>(MAX_QUEUES) || bv < 1 || bv > static_cast<std::int64_t>(MAX_BUFFER) ||
        tv < 1 || tv > static_cast<std::int64_t>(MAX_SLOTS)) return -1;
    const auto m = static_cast<std::size_t>(mv), b = static_cast<std::size_t>(bv), t = static_cast<std::size_t>(tv);
    const auto cells = m * t;
    if (length != 3 + 2 * cells) return -1;
    for (std::size_t cell = 0; cell < cells; ++cell) {
        const auto flag = input[3 + cell], priority = input[3 + cells + cell];
        if (flag < 0 || flag > 1 || priority < 0 || static_cast<std::uint64_t>(priority) > MAX_PRIORITY) return -1;
    }
    std::array<std::size_t, MAX_QUEUES> load{}, count{};
    std::array<std::array<Tag, MAX_BUFFER>, MAX_QUEUES> tags{};
    std::array<std::int64_t, MAX_SLOTS> trace{};
    for (std::size_t slot = 0; slot < t; ++slot) {
        for (std::size_t q = 0; q < m; ++q) {
            const auto cell = slot * m + q;
            if (input[3 + cell] == 0 || load[q] == b) continue;
            if (count[q] == b) {
                for (std::size_t i = 1; i < count[q]; ++i) tags[q][i - 1] = tags[q][i];
                --count[q];
            }
            tags[q][count[q]++] = Tag{input[3 + cells + cell], false};
            ++load[q];
        }
        std::size_t best_q = m, best_i = 0;
        std::int64_t best_priority = -1;
        for (std::size_t q = 0; q < m; ++q) for (std::size_t i = 0; i < count[q]; ++i) {
            if (!tags[q][i].marked && (best_q == m || tags[q][i].priority > best_priority)) {
                best_q = q; best_i = i; best_priority = tags[q][i].priority;
            }
        }
        if (best_q != m) tags[best_q][best_i].marked = true;
        else {
            best_q = m;
            for (std::size_t q = 0; q < m; ++q) if (load[q] != 0) { best_q = q; break; }
        }
        if (best_q == m) trace[slot] = -1;
        else { trace[slot] = static_cast<std::int64_t>(best_q); --load[best_q]; }
    }
    const auto bytes = 8 * t;
    if (output == nullptr || capacity < bytes) return -2;
    std::array<std::uint8_t, MAX_OUTPUT_BYTES> staged{};
    for (std::size_t slot = 0; slot < t; ++slot) store_i64_le(staged.data(), 8 * slot, trace[slot]);
    for (std::size_t byte = 0; byte < bytes; ++byte) output[byte] = staged[byte];
    return static_cast<std::int64_t>(bytes);
}
