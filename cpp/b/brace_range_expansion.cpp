#include <array>
#include <cstddef>
#include <cstdint>

namespace {
struct Plan {
    int open, close, start, end, step, letter, pad, count;
};

bool endpoint(const std::int64_t* p, int begin, int end, int& value,
              int& letter, int& width, int& upper) {
    const int n = end - begin;
    if (n == 1 && ((p[begin] >= 65 && p[begin] <= 90) ||
                   (p[begin] >= 97 && p[begin] <= 122))) {
        value = static_cast<int>(p[begin]); letter = 1; width = 1;
        upper = p[begin] <= 90;
        return true;
    }
    if (n < 1 || n > 4) return false;
    value = 0;
    for (int i = begin; i < end; ++i) {
        if (p[i] < 48 || p[i] > 57) return false;
        value = value * 10 + static_cast<int>(p[i]) - 48;
    }
    letter = 0; width = n; upper = 0;
    return true;
}

bool parse_step(const std::int64_t* p, int begin, int end, int& step) {
    int sign = 1;
    if (begin < end && (p[begin] == 43 || p[begin] == 45)) {
        if (p[begin] == 45) sign = -1;
        ++begin;
    }
    if (end - begin < 1) return false;
    int value = 0;
    for (int i = begin; i < end; ++i) {
        if (p[i] < 48 || p[i] > 57) return false;
        if (value < 10000) {
            value = value * 10 + static_cast<int>(p[i]) - 48;
            if (value > 10000) value = 10000;
        }
    }
    if (value == 0) return false;
    step = sign * value;
    return true;
}

bool make_plan(const std::int64_t* p, int n, Plan& plan) {
    if (n < 1 || n > 64) return false;
    int open = -1, close = -1;
    for (int i = 0; i < n; ++i) {
        if (p[i] < 32 || p[i] > 126) return false;
        if (p[i] == 123) {
            if (open >= 0) return false;
            open = i;
        } else if (p[i] == 125) {
            if (close >= 0) return false;
            close = i;
        }
    }
    if (open < 0 || close <= open || open + n - close - 1 > 32) return false;
    int sep1 = -1, sep2 = -1;
    for (int i = open + 1; i + 1 < close; ++i) {
        if (p[i] == 46 && p[i+1] == 46) {
            if (sep1 < 0) sep1 = i;
            else if (sep2 < 0) sep2 = i;
            else return false;
            ++i;
        }
    }
    if (sep1 < 0) return false;
    int start, end, start_letter, end_letter, sw, ew, su, eu;
    if (!endpoint(p, open+1, sep1, start, start_letter, sw, su) ||
        !endpoint(p, sep1+2, sep2 < 0 ? close : sep2, end, end_letter, ew, eu) ||
        start_letter != end_letter || (start_letter && su != eu)) return false;
    int step;
    if (sep2 < 0) step = start <= end ? 1 : -1;
    else if (!parse_step(p, sep2+2, close, step)) return false;
    if ((start < end && step <= 0) || (start > end && step >= 0)) return false;
    const int count = start == end ? 1 :
        (start < end ? (end-start)/step : (start-end)/-step) + 1;
    if (count > 16) return false;
    int pad = 0;
    if (!start_letter && (p[open+1] == 48 || p[sep1+2] == 48)) pad = sw > ew ? sw : ew;
    plan = {open, close, start, end, step, start_letter, pad, count};
    return true;
}
}

extern "C" std::int64_t brace_range_expansion(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (!input || length < 2 || length > 65) return -1;
    const int n = static_cast<int>(input[0]);
    if (n < 1 || n > 64 || length != static_cast<std::size_t>(n+1)) return -1;
    Plan plan{};
    if (!make_plan(input+1, n, plan)) return -1;
    std::array<std::uint8_t, 591> staged{};
    int out = 0, value = plan.start;
    const int suffix_start = plan.close+1, suffix_len = n-suffix_start;
    for (int item = 0; item < plan.count; ++item) {
        if (item) staged[out++] = 0;
        for (int i = 0; i < plan.open; ++i) staged[out++] = static_cast<std::uint8_t>(input[1+i]);
        if (plan.letter) staged[out++] = static_cast<std::uint8_t>(value);
        else {
            int digits[4], used = 0, remaining = value;
            do { digits[used++] = remaining%10; remaining/=10; } while (remaining > 0);
            while (used < plan.pad) staged[out++] = 48;
            while (used) staged[out++] = static_cast<std::uint8_t>(48+digits[--used]);
        }
        for (int i = 0; i < suffix_len; ++i)
            staged[out++] = static_cast<std::uint8_t>(input[1+suffix_start+i]);
        value += plan.step;
    }
    if (!output || capacity < static_cast<std::size_t>(out)) return -2;
    for (int i = 0; i < out; ++i) output[i] = staged[i];
    return out;
}
