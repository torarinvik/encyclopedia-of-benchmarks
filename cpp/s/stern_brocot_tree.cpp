#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_queries = 128;
constexpr std::size_t max_runs = 64;
constexpr std::size_t max_input_length = 16'384;
constexpr std::size_t max_output_words = 32'768;
constexpr std::int64_t max_component = 1'000'000'000;

struct Run { std::int64_t direction; std::int64_t count; };
struct Decoded {
    std::int64_t numerator, denominator;
    std::int64_t lower_num, lower_den, upper_num, upper_den;
};

std::int64_t gcd(std::int64_t a, std::int64_t b) {
    while (b != 0) { const auto remainder = a % b; a = b; b = remainder; }
    return a;
}

bool valid_fraction(std::int64_t numerator, std::int64_t denominator) {
    return numerator >= 1 && numerator <= max_component
        && denominator >= 1 && denominator <= max_component
        && gcd(numerator, denominator) == 1;
}

bool encode_path(std::int64_t numerator, std::int64_t denominator,
                 std::array<Run, max_runs>& runs, std::size_t& run_count) {
    run_count = 0;
    while (numerator != denominator) {
        if (run_count == max_runs) return false;
        if (numerator < denominator) {
            const auto count = (denominator - 1) / numerator;
            runs[run_count++] = {0, count};
            denominator -= count * numerator;
        } else {
            const auto count = (numerator - 1) / denominator;
            runs[run_count++] = {1, count};
            numerator -= count * denominator;
        }
    }
    return true;
}

bool decode_path(const Run* runs, std::size_t run_count, Decoded& result) {
    std::int64_t ln = 0, ld = 1, un = 1, ud = 0, previous = -1;
    for (std::size_t i = 0; i < run_count; ++i) {
        const auto [direction, count] = runs[i];
        if ((direction != 0 && direction != 1) || count < 1 || count > max_component
            || direction == previous) return false;
        if (direction == 0) {
            un += count * ln; ud += count * ld;
            if (un > max_component || ud > max_component) return false;
        } else {
            ln += count * un; ld += count * ud;
            if (ln > max_component || ld > max_component) return false;
        }
        previous = direction;
    }
    const auto numerator = ln + un, denominator = ld + ud;
    if (!valid_fraction(numerator, denominator)) return false;
    result = {numerator, denominator, ln, ld, un, ud};
    return true;
}

std::size_t common_prefix(const Run* left, std::size_t left_count,
                          const Run* right, std::size_t right_count,
                          std::array<Run, max_runs>& prefix) {
    std::size_t i = 0, j = 0, count = 0;
    std::int64_t left_used = 0, right_used = 0;
    while (i < left_count && j < right_count && left[i].direction == right[j].direction) {
        const auto shared = (left[i].count - left_used < right[j].count - right_used)
            ? left[i].count - left_used : right[j].count - right_used;
        prefix[count++] = {left[i].direction, shared};
        left_used += shared; right_used += shared;
        if (left_used == left[i].count) { ++i; left_used = 0; }
        if (right_used == right[j].count) { ++j; right_used = 0; }
    }
    return count;
}

bool append(std::array<std::int64_t, max_output_words>& words,
            std::size_t& length, std::int64_t value) {
    if (length == max_output_words) return false;
    words[length++] = value;
    return true;
}
} // namespace

extern "C" std::int64_t stern_brocot_tree(const std::int64_t* input, std::size_t length,
                                            std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    const auto query_count = input[0];
    if (query_count < 1 || query_count > static_cast<std::int64_t>(max_queries)) return -1;
    std::array<std::int64_t, max_output_words> words{};
    std::size_t word_count = 0, position = 1;
    for (std::int64_t query = 0; query < query_count; ++query) {
        if (position >= length) return -1;
        const auto operation = input[position++];
        if (operation == 0) {
            if (position + 2 > length) return -1;
            const auto numerator = input[position++], denominator = input[position++];
            if (!valid_fraction(numerator, denominator)) return -1;
            std::array<Run, max_runs> runs{};
            std::size_t run_count;
            if (!encode_path(numerator, denominator, runs, run_count)
                || !append(words, word_count, operation)
                || !append(words, word_count, static_cast<std::int64_t>(run_count))) return -1;
            for (std::size_t i = 0; i < run_count; ++i)
                if (!append(words, word_count, runs[i].direction)
                    || !append(words, word_count, runs[i].count)) return -1;
        } else if (operation == 1) {
            if (position >= length) return -1;
            const auto raw_count = input[position++];
            if (raw_count < 0 || raw_count > static_cast<std::int64_t>(max_runs)
                || position + static_cast<std::size_t>(raw_count) * 2 > length) return -1;
            const auto run_count = static_cast<std::size_t>(raw_count);
            std::array<Run, max_runs> runs{};
            for (std::size_t i = 0; i < run_count; ++i) {
                runs[i] = {input[position], input[position + 1]}; position += 2;
            }
            Decoded decoded{};
            if (!decode_path(runs.data(), run_count, decoded)
                || !append(words, word_count, operation)
                || !append(words, word_count, decoded.numerator)
                || !append(words, word_count, decoded.denominator)) return -1;
        } else if (operation == 2) {
            if (position + 4 > length) return -1;
            const auto a = input[position++], b = input[position++];
            const auto c = input[position++], d = input[position++];
            if (!valid_fraction(a, b) || !valid_fraction(c, d)) return -1;
            std::array<Run, max_runs> left{}, right{}, prefix{};
            std::size_t left_count, right_count;
            if (!encode_path(a, b, left, left_count) || !encode_path(c, d, right, right_count)) return -1;
            const auto prefix_count = common_prefix(left.data(), left_count, right.data(), right_count, prefix);
            Decoded decoded{};
            if (!decode_path(prefix.data(), prefix_count, decoded)
                || !append(words, word_count, operation)
                || !append(words, word_count, decoded.numerator)
                || !append(words, word_count, decoded.denominator)) return -1;
        } else if (operation == 3) {
            if (position + 3 > length) return -1;
            const auto depth = input[position++], numerator = input[position++], denominator = input[position++];
            if (depth < 1 || depth > max_component || !valid_fraction(numerator, denominator)) return -1;
            std::array<Run, max_runs> path{}, prefix{};
            std::size_t path_count;
            if (!encode_path(numerator, denominator, path, path_count)) return -1;
            std::int64_t total_depth = 0;
            for (std::size_t i = 0; i < path_count; ++i) total_depth += path[i].count;
            if (!append(words, word_count, operation)) return -1;
            if (depth > total_depth) {
                if (!append(words, word_count, -1)) return -1;
            } else {
                auto remaining = depth;
                std::size_t prefix_count = 0;
                for (std::size_t i = 0; i < path_count && remaining > 0; ++i) {
                    const auto take = path[i].count < remaining ? path[i].count : remaining;
                    prefix[prefix_count++] = {path[i].direction, take}; remaining -= take;
                }
                Decoded decoded{};
                if (!decode_path(prefix.data(), prefix_count, decoded)
                    || !append(words, word_count, decoded.numerator)
                    || !append(words, word_count, decoded.denominator)) return -1;
            }
        } else if (operation == 4) {
            if (position + 2 > length) return -1;
            const auto numerator = input[position++], denominator = input[position++];
            if (!valid_fraction(numerator, denominator)) return -1;
            std::array<Run, max_runs> path{};
            std::size_t path_count;
            if (!encode_path(numerator, denominator, path, path_count)) return -1;
            Decoded decoded{};
            if (!decode_path(path.data(), path_count, decoded)
                || !append(words, word_count, operation)
                || !append(words, word_count, decoded.lower_num)
                || !append(words, word_count, decoded.lower_den)
                || !append(words, word_count, decoded.upper_num)
                || !append(words, word_count, decoded.upper_den)) return -1;
        } else {
            return -1;
        }
    }
    if (position != length) return -1;
    const std::size_t byte_count = word_count * 8;
    if (output_capacity < byte_count || output == nullptr) return -2;
    for (std::size_t i = 0; i < word_count; ++i) {
        const auto bits = static_cast<std::uint64_t>(words[i]);
        for (std::size_t byte = 0; byte < 8; ++byte)
            output[i * 8 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
    }
    return query_count;
}
