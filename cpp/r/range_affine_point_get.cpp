#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 256, MAX_Q = 256, MAX_BASE = 256;
constexpr std::size_t MAX_TREE = 2 * MAX_BASE;
constexpr std::size_t MAX_PARSEABLE_INPUT = 2 + MAX_N + 5 * MAX_Q + 1;
constexpr std::int64_t MOD = 998244353;
struct Operation { std::int64_t kind{}, left{}, right{}, multiplier{}, offset{}; };

void apply_tag(std::array<std::int64_t, MAX_TREE>& mul,
               std::array<std::int64_t, MAX_TREE>& add, std::size_t node,
               std::int64_t multiplier, std::int64_t offset) {
    add[node] = (multiplier * add[node] + offset) % MOD;
    mul[node] = (multiplier * mul[node]) % MOD;
}

void push(std::array<std::int64_t, MAX_TREE>& mul,
          std::array<std::int64_t, MAX_TREE>& add, std::size_t node) {
    if (mul[node] != 1 || add[node] != 0) {
        apply_tag(mul, add, 2 * node, mul[node], add[node]);
        apply_tag(mul, add, 2 * node + 1, mul[node], add[node]);
        mul[node] = 1;
        add[node] = 0;
    }
}

void range_apply(std::array<std::int64_t, MAX_TREE>& mul,
                 std::array<std::int64_t, MAX_TREE>& add,
                 std::size_t node, std::size_t seg_left, std::size_t seg_right,
                 std::size_t left, std::size_t right,
                 std::int64_t multiplier, std::int64_t offset) {
    if (right <= seg_left || seg_right <= left) return;
    if (left <= seg_left && seg_right <= right) {
        apply_tag(mul, add, node, multiplier, offset);
        return;
    }
    push(mul, add, node);
    const std::size_t middle = seg_left + (seg_right - seg_left) / 2;
    range_apply(mul, add, 2 * node, seg_left, middle, left, right, multiplier, offset);
    range_apply(mul, add, 2 * node + 1, middle, seg_right, left, right, multiplier, offset);
}

std::int64_t point_get(std::array<std::int64_t, MAX_TREE>& mul,
                       std::array<std::int64_t, MAX_TREE>& add,
                       const std::array<std::int64_t, MAX_N>& initial,
                       std::size_t node, std::size_t seg_left,
                       std::size_t seg_right, std::size_t index) {
    if (seg_right - seg_left == 1)
        return (mul[node] * initial[index] + add[node]) % MOD;
    push(mul, add, node);
    const std::size_t middle = seg_left + (seg_right - seg_left) / 2;
    if (index < middle)
        return point_get(mul, add, initial, 2 * node, seg_left, middle, index);
    return point_get(mul, add, initial, 2 * node + 1, middle, seg_right, index);
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t range_affine_point_get(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > MAX_PARSEABLE_INPUT) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(MAX_N) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(MAX_Q)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto q = static_cast<std::size_t>(input[1]);
    if (2 + n > length) return -1;
    std::array<std::int64_t, MAX_N> initial{};
    std::array<Operation, MAX_Q> operations{};
    for (std::size_t i = 0; i < n; ++i) {
        initial[i] = input[2 + i];
        if (initial[i] < 0 || initial[i] >= MOD) return -1;
    }
    std::size_t cursor = 2 + n, query_count = 0;
    for (std::size_t i = 0; i < q; ++i) {
        if (cursor >= length) return -1;
        const auto kind = input[cursor++];
        if (kind == 0) {
            if (cursor + 4 > length) return -1;
            const auto left = input[cursor], right = input[cursor + 1];
            const auto multiplier = input[cursor + 2], offset = input[cursor + 3];
            cursor += 4;
            if (left < 0 || left >= right || right > static_cast<std::int64_t>(n) ||
                multiplier < 1 || multiplier >= MOD || offset < 0 || offset >= MOD) return -1;
            operations[i] = {kind, left, right, multiplier, offset};
        } else if (kind == 1) {
            if (cursor >= length) return -1;
            const auto index = input[cursor++];
            if (index < 0 || index >= static_cast<std::int64_t>(n)) return -1;
            operations[i] = {kind, index, 0, 0, 0};
            ++query_count;
        } else return -1;
    }
    if (cursor != length) return -1;
    const std::size_t output_bytes = 8 * query_count;
    if (output_bytes > 0 && (output == nullptr || capacity < output_bytes)) return -2;

    std::size_t base = 1;
    while (base < n) base *= 2;
    std::array<std::int64_t, MAX_TREE> mul{};
    std::array<std::int64_t, MAX_TREE> add{};
    mul.fill(1);
    std::size_t answer = 0;
    for (std::size_t i = 0; i < q; ++i) {
        const auto& operation = operations[i];
        if (operation.kind == 0) {
            range_apply(mul, add, 1, 0, base, operation.left, operation.right,
                        operation.multiplier, operation.offset);
        } else {
            const auto value = point_get(mul, add, initial, 1, 0, base, operation.left);
            store_i64_le(output, 8 * answer++, value);
        }
    }
    return static_cast<std::int64_t>(output_bytes);
}
