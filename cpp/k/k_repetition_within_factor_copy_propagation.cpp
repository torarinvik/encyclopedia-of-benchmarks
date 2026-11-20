#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t N = 16, K = 3, SYMBOL_MAX = 5, INPUT_MAX = 1557;
constexpr std::size_t RECORD_MAX = 372, PERIODS = 9, BIT_WORDS = 39, OUTPUT_MAX = 11912;

struct Record { std::int32_t start, end, period, errors; };
struct State {
    std::array<std::int32_t, N> word{};
    std::array<std::int32_t, N> starts{}, ends{}, copies{};
    std::array<Record, RECORD_MAX> records{};
    std::array<std::uint64_t, BIT_WORDS> known{}, generated{};
    std::size_t n{}, factors{}, count{};
    std::int32_t budget{};
};

int lce(const State& s, int left, int right) {
    int length = 0;
    while (left + length < static_cast<int>(s.n) && right + length < static_cast<int>(s.n)
           && s.word[static_cast<std::size_t>(left + length)] == s.word[static_cast<std::size_t>(right + length)]) ++length;
    return length;
}

std::size_t bit_index(int start, int end, int period) {
    return (static_cast<std::size_t>(start) * (N + 1) + static_cast<std::size_t>(end)) * PERIODS
           + static_cast<std::size_t>(period);
}

bool marked(const std::array<std::uint64_t, BIT_WORDS>& bits, std::size_t bit) {
    return ((bits[bit / 64] >> (bit % 64)) & 1U) != 0;
}

bool less_record(const Record& a, const Record& b) {
    if (a.start != b.start) return a.start < b.start;
    if (a.end != b.end) return a.end < b.end;
    if (a.period != b.period) return a.period < b.period;
    return a.errors < b.errors;
}

void add(State& s, Record record, bool is_new) {
    const auto bit = bit_index(record.start, record.end, record.period);
    if (marked(s.known, bit)) return;
    s.known[bit / 64] |= std::uint64_t{1} << (bit % 64);
    if (is_new) s.generated[bit / 64] |= std::uint64_t{1} << (bit % 64);
    auto at = s.count;
    while (at != 0 && less_record(record, s.records[at - 1])) {
        s.records[at] = s.records[at - 1];
        --at;
    }
    s.records[at] = record;
    ++s.count;
}

bool factors_valid(const State& s) {
    if (s.factors == 0 || s.factors > s.n) return false;
    int position = 0;
    for (std::size_t f = 0; f < s.factors; ++f) {
        const int a = s.starts[f], b = s.ends[f], c = s.copies[f];
        if (a != position || a < 0 || b <= a || b > static_cast<int>(s.n)) return false;
        if (f == 0) {
            if (a != 0 || b != 1 || c != -1) return false;
            position = b;
            continue;
        }
        int longest = 0;
        for (int previous = 0; previous < a; ++previous) longest = std::max(longest, lce(s, previous, a));
        if (b != std::min(static_cast<int>(s.n), a + longest + 1)) return false;
        const int prefix = b - a - 1;
        if (prefix == 0) {
            if (c != -1) return false;
        } else if (c < 0 || c >= a || lce(s, c, a) != prefix) return false;
        position = b;
    }
    return position == static_cast<int>(s.n);
}

int errors_for(const State& s, int start, int end, int period) {
    int errors = 0;
    for (int i = start; i < end - period; ++i)
        if (s.word[static_cast<std::size_t>(i)] != s.word[static_cast<std::size_t>(i + period)]) ++errors;
    return errors;
}

bool seed_valid(const State& s, const Record& r) {
    const int a = r.start, b = r.end, p = r.period;
    if (a < 0 || a >= b || b > static_cast<int>(s.n) || p < 1 || p > static_cast<int>(s.n / 2) || b - a < 2 * p)
        return false;
    const int errors = errors_for(s, a, b, p);
    if (errors != r.errors || errors > s.budget) return false;
    if (a > 0 && errors + (s.word[static_cast<std::size_t>(a - 1)] != s.word[static_cast<std::size_t>(a + p - 1)]) <= s.budget)
        return false;
    if (b < static_cast<int>(s.n) && errors + (s.word[static_cast<std::size_t>(b - p)] != s.word[static_cast<std::size_t>(b)]) <= s.budget)
        return false;
    return true;
}

void propagate(State& s) {
    for (std::size_t f = 0; f < s.factors; ++f) {
        const int a = s.starts[f], b = s.ends[f], c = s.copies[f];
        const int copied = b - a - 1;
        if (copied <= 0) continue;
        const int delta = a - c, copy_end = c + copied;
        for (int target = a + 1; target < b - 1; ++target) {
            const int source_start = target - delta;
            std::size_t index = 0;
            while (index < s.count && s.records[index].start < source_start) ++index;
            while (index < s.count && s.records[index].start == source_start) {
                const Record source = s.records[index];
                if (source.end > copy_end) break;
                const int target_end = source.end + delta;
                if (target_end <= b - 2) add(s, {target, target_end, source.period, source.errors}, true);
                ++index;
            }
        }
    }
}

void put(std::uint8_t* out, std::size_t offset, std::uint64_t value) {
    for (std::size_t b = 0; b < 8; ++b) out[offset + b] = static_cast<std::uint8_t>(value >> (8 * b));
}
} // namespace

extern "C" std::int64_t k_repetition_within_factor_copy_propagation(
    const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > INPUT_MAX) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(N) || input[1] < 0 || input[1] > static_cast<std::int64_t>(K)) return -1;
    State s{};
    s.n = static_cast<std::size_t>(input[0]);
    s.budget = static_cast<std::int32_t>(input[1]);
    if (length < s.n + 3) return -1;
    std::size_t cursor = 2;
    for (std::size_t i = 0; i < s.n; ++i) {
        if (input[cursor] < 0 || input[cursor] > static_cast<std::int64_t>(SYMBOL_MAX)) return -1;
        s.word[i] = static_cast<std::int32_t>(input[cursor++]);
    }
    for (std::size_t i = 0; i + 1 < s.n; ++i) if (s.word[i] == s.word[s.n - 1]) return -1;
    if (cursor >= length || input[cursor] < 1 || input[cursor] > static_cast<std::int64_t>(s.n)) return -1;
    s.factors = static_cast<std::size_t>(input[cursor++]);
    if (cursor + 3 * s.factors >= length) return -1;
    for (std::size_t i = 0; i < s.factors; ++i) {
        const auto a = input[cursor], b = input[cursor + 1], c = input[cursor + 2];
        if (a < 0 || a > static_cast<std::int64_t>(s.n) || b < 0 || b > static_cast<std::int64_t>(s.n) || c < -1 || c > static_cast<std::int64_t>(s.n)) return -1;
        s.starts[i] = static_cast<std::int32_t>(a); s.ends[i] = static_cast<std::int32_t>(b); s.copies[i] = static_cast<std::int32_t>(c);
        cursor += 3;
    }
    if (cursor >= length || !factors_valid(s)) return -1;
    const auto seed_count_value = input[cursor++];
    if (seed_count_value < 0 || seed_count_value > static_cast<std::int64_t>(RECORD_MAX) ||
        cursor + 4 * static_cast<std::size_t>(seed_count_value) != length) return -1;
    for (std::size_t i = 0; i < static_cast<std::size_t>(seed_count_value); ++i) {
        const auto a = input[cursor], b = input[cursor + 1], p = input[cursor + 2], e = input[cursor + 3];
        if (a < 0 || a > static_cast<std::int64_t>(s.n) || b < 0 || b > static_cast<std::int64_t>(s.n) || p < 0 || p > static_cast<std::int64_t>(s.n) || e < 0 || e > static_cast<std::int64_t>(K)) return -1;
        Record seed{static_cast<std::int32_t>(a), static_cast<std::int32_t>(b), static_cast<std::int32_t>(p), static_cast<std::int32_t>(e)};
        if (!seed_valid(s, seed)) return -1;
        add(s, seed, false);
        cursor += 4;
    }
    propagate(s);
    std::size_t count = 0;
    for (std::size_t i = 0; i < s.count; ++i) {
        const auto& r = s.records[i];
        count += marked(s.generated, bit_index(r.start, r.end, r.period)) ? 1U : 0U;
    }
    const std::size_t bytes = 8 + 32 * count;
    if (bytes > OUTPUT_MAX) return -1;
    if (output == nullptr || capacity < bytes) return -2;
    put(output, 0, count);
    std::size_t offset = 8;
    for (std::size_t i = 0; i < s.count; ++i) {
        const auto& r = s.records[i];
        if (!marked(s.generated, bit_index(r.start, r.end, r.period))) continue;
        put(output, offset, static_cast<std::uint64_t>(r.start)); offset += 8;
        put(output, offset, static_cast<std::uint64_t>(r.end)); offset += 8;
        put(output, offset, static_cast<std::uint64_t>(r.period)); offset += 8;
        put(output, offset, static_cast<std::uint64_t>(r.errors)); offset += 8;
    }
    return static_cast<std::int64_t>(bytes);
}
