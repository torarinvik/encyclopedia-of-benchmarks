#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace {
constexpr std::size_t max_n = 32, max_q = 32, max_input = 195;
struct Run { std::int64_t left, right, value; };
struct Operation { std::int64_t kind, left, right, arg, extra; };
std::size_t lower_bound(const std::vector<Run>& runs, std::int64_t point) {
    return static_cast<std::size_t>(std::lower_bound(runs.begin(), runs.end(), point,
        [](const Run& run, std::int64_t key) { return run.left < key; }) - runs.begin());
}
void split_at(std::vector<Run>& runs, std::int64_t point, std::int64_t n) {
    if (point <= 0 || point >= n) return;
    const auto at = lower_bound(runs, point);
    if (at < runs.size() && runs[at].left == point) return;
    const Run old = runs[at - 1];
    runs[at - 1].right = point - 1;
    runs.insert(runs.begin() + static_cast<std::ptrdiff_t>(at), Run{point, old.right, old.value});
}
void coalesce(std::vector<Run>& runs) {
    std::size_t write = 0;
    for (std::size_t read = 0; read < runs.size(); ++read) {
        if (write && runs[write - 1].right + 1 == runs[read].left && runs[write - 1].value == runs[read].value)
            runs[write - 1].right = runs[read].right;
        else runs[write++] = runs[read];
    }
    runs.resize(write);
}
std::int64_t modular_power(std::int64_t base, std::int64_t exponent, std::int64_t modulus) {
    std::int64_t value = base % modulus; if (value < 0) value += modulus;
    std::int64_t result = 1 % modulus;
    while (exponent) { if (exponent & 1) result = result * value % modulus; value = value * value % modulus; exponent >>= 1; }
    return result;
}
void store_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t old_driver_tree(const std::int64_t* input, std::size_t length,
                                          std::uint8_t* output, std::size_t capacity) {
    if (!input || length < 2 || length > max_input) return -1;
    const auto nv = input[0], qv = input[1];
    if (nv < 1 || nv > static_cast<std::int64_t>(max_n) || qv < 0 || qv > static_cast<std::int64_t>(max_q) || length < 2 + static_cast<std::size_t>(nv)) return -1;
    const auto n = static_cast<std::size_t>(nv), q = static_cast<std::size_t>(qv);
    std::vector<std::int64_t> initial(n);
    for (std::size_t i = 0; i < n; ++i) { initial[i] = input[2 + i]; if (initial[i] < -1000 || initial[i] > 1000) return -1; }
    std::vector<Operation> ops; ops.reserve(q); std::size_t cursor = 2 + n, answer_count = 0;
    for (std::size_t i = 0; i < q; ++i) {
        if (cursor >= length) return -1;
        const auto kind = input[cursor++];
        const std::size_t words = kind == 3 ? 4 : kind >= 0 && kind <= 2 ? 3 : 0;
        if (!words || length - cursor < words) return -1;
        const Operation op{kind, input[cursor], input[cursor + 1], input[cursor + 2], kind == 3 ? input[cursor + 3] : 0}; cursor += words;
        if (op.left < 0 || op.left > op.right || op.right >= nv) return -1;
        if ((kind <= 1 && (op.arg < -1000 || op.arg > 1000)) || (kind == 2 && (op.arg < 1 || op.arg > op.right - op.left + 1)) ||
            (kind == 3 && (op.arg < 0 || op.arg > 8 || op.extra < 1 || op.extra > 1'000'000'000))) return -1;
        if (kind >= 2) ++answer_count;
        ops.push_back(op);
    }
    if (cursor != length || length > 2 + max_n + 5 * max_q) return -1;
    const auto required = 8 * answer_count;
    if (required && (!output || capacity < required)) return -2;
    std::vector<Run> runs;
    for (std::size_t i = 0; i < n; ++i) {
        if (!runs.empty() && runs.back().value == initial[i]) runs.back().right = static_cast<std::int64_t>(i);
        else runs.push_back({static_cast<std::int64_t>(i), static_cast<std::int64_t>(i), initial[i]});
    }
    std::size_t written = 0;
    for (const auto& op : ops) {
        if (op.kind <= 1) {
            split_at(runs, op.right + 1, nv); split_at(runs, op.left, nv);
            const auto start = lower_bound(runs, op.left), end = lower_bound(runs, op.right + 1);
            if (op.kind == 0) runs.erase(runs.begin() + static_cast<std::ptrdiff_t>(start), runs.begin() + static_cast<std::ptrdiff_t>(end)), runs.insert(runs.begin() + static_cast<std::ptrdiff_t>(start), Run{op.left, op.right, op.arg});
            else for (auto i = start; i < end; ++i) runs[i].value += op.arg;
            coalesce(runs);
        } else if (op.kind == 2) {
            std::vector<std::int64_t> ordered;
            for (const auto& run : runs) for (auto i = std::max(run.left, op.left); i <= std::min(run.right, op.right); ++i) ordered.push_back(run.value);
            std::sort(ordered.begin(), ordered.end()); store_le(output, 8 * written++, ordered[static_cast<std::size_t>(op.arg - 1)]);
        } else {
            std::int64_t total = 0;
            for (const auto& run : runs) {
                const auto lo = std::max(run.left, op.left), hi = std::min(run.right, op.right);
                if (lo <= hi) total = (total + (hi - lo + 1) * modular_power(run.value, op.arg, op.extra)) % op.extra;
            }
            store_le(output, 8 * written++, total);
        }
    }
    return static_cast<std::int64_t>(required);
}
