#include <array>
#include <cstddef>
#include <cstdint>
#include <climits>

namespace {
constexpr int MAX_N = 5;
constexpr int MAX_STATES = 3840;
constexpr int MAX_MOVES = 10;
constexpr std::size_t MAX_OUTPUT_BYTES = 168;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

int encode(const std::array<std::int64_t, MAX_N> &permutation, int n) {
    int rank = 0;
    unsigned signs = 0;
    for (int i = 0; i < n; ++i) {
        const int value = static_cast<int>(permutation[i] < 0 ? -permutation[i] : permutation[i]);
        int smaller = 0;
        for (int j = i + 1; j < n; ++j) {
            const int other = static_cast<int>(permutation[j] < 0 ? -permutation[j] : permutation[j]);
            if (other < value) ++smaller;
        }
        rank = rank * (n - i) + smaller;
        if (permutation[i] < 0) signs |= 1u << (value - 1);
    }
    return rank * (1 << n) + static_cast<int>(signs);
}

void decode_state(int state, int n, const std::array<int, MAX_N + 1> &factorials,
                  std::array<std::int64_t, MAX_N> &permutation) {
    const unsigned sign_count = 1u << n;
    int rank = state / static_cast<int>(sign_count);
    const unsigned signs = static_cast<unsigned>(state) % sign_count;
    std::array<int, MAX_N> available{};
    for (int i = 0; i < n; ++i) available[i] = i + 1;
    int remaining = n;
    for (int i = 0; i < n; ++i) {
        const int factor = factorials[n - i - 1];
        const int digit = rank / factor;
        rank %= factor;
        const int value = available[digit];
        for (int j = digit; j + 1 < remaining; ++j) available[j] = available[j + 1];
        --remaining;
        permutation[i] = signs & (1u << (value - 1)) ? -value : value;
    }
}

void reverse_signed(std::array<std::int64_t, MAX_N> &permutation, int left, int right) {
    while (left < right) {
        const auto a = permutation[left], b = permutation[right];
        permutation[left++] = -b;
        permutation[right--] = -a;
    }
    if (left == right) permutation[left] = -permutation[left];
}
}

extern "C" std::int64_t signed_permutation_reversal_sequence(
    const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 3 || length > MAX_N + 1) return -1;
    const auto raw_n = input[0];
    if (raw_n < 2 || raw_n > MAX_N || length != static_cast<std::size_t>(raw_n) + 1) return -1;
    const int n = static_cast<int>(raw_n);
    unsigned seen = 0;
    std::array<std::int64_t, MAX_N> permutation{};
    for (int i = 0; i < n; ++i) {
        const auto value = input[i + 1];
        if (value == 0 || value == LLONG_MIN) return -1;
        const auto absolute = value < 0 ? -value : value;
        if (absolute > n) return -1;
        const unsigned bit = 1u << (static_cast<unsigned>(absolute) - 1u);
        if (seen & bit) return -1;
        seen |= bit;
        permutation[i] = value;
    }
    if (seen != (1u << n) - 1u) return -1;
    if (output == nullptr) return -2;

    const std::array<int, MAX_N + 1> factorials{1, 1, 2, 6, 24, 120};
    const int state_count = factorials[n] * (1 << n);
    std::array<std::int32_t, MAX_STATES> parent{};
    std::array<std::int32_t, MAX_STATES> queue{};
    std::array<std::int8_t, MAX_STATES> move_left{}, move_right{};
    for (int state = 0; state < state_count; ++state) parent[state] = -2;
    const int start = encode(permutation, n);
    int head = 0, tail = 0;
    parent[start] = -1;
    queue[tail++] = start;
    while (head < tail && parent[0] == -2) {
        const int current = queue[head++];
        std::array<std::int64_t, MAX_N> current_permutation{};
        decode_state(current, n, factorials, current_permutation);
        for (int left = 0; left < n && parent[0] == -2; ++left) {
            for (int right = left; right < n; ++right) {
                auto neighbor = current_permutation;
                reverse_signed(neighbor, left, right);
                const int next = encode(neighbor, n);
                if (parent[next] != -2) continue;
                parent[next] = current;
                move_left[next] = static_cast<std::int8_t>(left + 1);
                move_right[next] = static_cast<std::int8_t>(right + 1);
                queue[tail++] = next;
                if (next == 0) break;
            }
        }
    }
    if (parent[0] == -2) return -1;
    std::array<std::array<std::int64_t, 2>, MAX_MOVES> reverse_moves{};
    int move_count = 0, current = 0;
    while (parent[current] >= 0) {
        if (move_count == MAX_MOVES) return -1;
        reverse_moves[move_count++] = {move_left[current], move_right[current]};
        current = parent[current];
    }
    const auto output_bytes = 8u * (1u + 2u * static_cast<std::size_t>(move_count));
    if (capacity < output_bytes) return -2;
    std::array<std::uint8_t, MAX_OUTPUT_BYTES> staged{};
    store_i64_le(staged.data(), 0, move_count);
    for (int i = 0; i < move_count; ++i) {
        const int reverse_index = move_count - 1 - i;
        store_i64_le(staged.data(), 8u * (1u + 2u * static_cast<std::size_t>(i)), reverse_moves[reverse_index][0]);
        store_i64_le(staged.data(), 8u * (2u + 2u * static_cast<std::size_t>(i)), reverse_moves[reverse_index][1]);
    }
    for (std::size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return static_cast<std::int64_t>(output_bytes);
}
