#include <cstddef>
#include <cstdint>

namespace {
constexpr int MAX_N = 32;
constexpr std::size_t MAX_INPUT = 35, MAX_OUTPUT = 4096, MAX_RESULT = 512;
void bit(std::uint8_t *out, std::size_t &used, bool value) { out[used++] = value ? '1' : '0'; }
void raw_byte(std::uint8_t *out, std::size_t &used, std::uint8_t value) { out[used++] = value; }
void number(std::uint8_t *out, std::size_t &used, std::uint64_t value, int width) {
    for (int shift = width - 1; shift >= 0; --shift) bit(out, used, ((value >> shift) & 1u) != 0);
}
void unary(std::uint8_t *out, std::size_t &used, std::uint64_t value) {
    for (std::uint64_t i = 0; i < value; ++i) bit(out, used, true);
    bit(out, used, false);
}
int floor_log2(std::uint64_t value) {
    int width = -1;
    while (value != 0) { ++width; value >>= 1; }
    return width;
}
void minimal(std::uint8_t *out, std::size_t &used, std::uint64_t value, std::uint64_t universe) {
    if (universe == 1) return;
    const int low_width = floor_log2(universe);
    const auto short_count = (std::uint64_t{1} << (low_width + 1)) - universe;
    if (value < short_count) number(out, used, value, low_width);
    else number(out, used, value + short_count, low_width + 1);
}
void gamma(std::uint8_t *out, std::size_t &used, std::uint64_t value) {
    const auto shifted = value + 1;
    const int width = floor_log2(shifted);
    unary(out, used, static_cast<std::uint64_t>(width));
    number(out, used, shifted - (std::uint64_t{1} << width), width);
}
void delta(std::uint8_t *out, std::size_t &used, std::uint64_t value) {
    const auto shifted = value + 1;
    const int width = floor_log2(shifted);
    gamma(out, used, static_cast<std::uint64_t>(width));
    number(out, used, shifted - (std::uint64_t{1} << width), width);
}
void interpolative(std::uint8_t *out, std::size_t &used, const std::int64_t *values,
                   int left, int right, std::int64_t low, std::int64_t high) {
    if (left >= right) return;
    const int middle = left + (right - left - 1) / 2;
    const auto value = values[middle];
    const auto lower = low + (middle - left);
    const auto upper = high - (right - middle - 1);
    minimal(out, used, static_cast<std::uint64_t>(value - lower), static_cast<std::uint64_t>(upper - lower));
    interpolative(out, used, values, left, middle, low, value);
    interpolative(out, used, values, middle + 1, right, value + 1, high);
}
void simple9(std::uint8_t *out, std::size_t &used, const std::int64_t *values, int n) {
    constexpr int slots[9] = {28,14,9,7,5,4,3,2,1};
    constexpr int widths[9] = {1,2,3,4,5,7,9,14,28};
    int position = 0;
    while (position < n) {
        int selector=0,take=0,width=0;
        for (int s=0;s<9;++s) {
            const int candidate_count = slots[s] < n-position ? slots[s] : n-position;
            bool fits=true;
            for (int j=0;j<candidate_count;++j)
                if (static_cast<std::uint64_t>(values[position+j]) >= (std::uint64_t{1} << widths[s])) fits=false;
            if (fits) { selector=s;take=candidate_count;width=widths[s];break; }
        }
        std::uint64_t word=static_cast<std::uint64_t>(selector)<<28;
        for (int j=0;j<take;++j) {
            const int shift=28-width*(j+1);
            word |= static_cast<std::uint64_t>(values[position+j]) << shift;
        }
        number(out,used,word,32);
        position+=take;
    }
}
}

extern "C" std::int64_t integer_sequence_codes(const std::int64_t *input, std::size_t length,
                                                std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 4 || length > MAX_INPUT) return -1;
    const auto mode = input[0], n0 = input[1], parameter = input[2];
    if (mode < 0 || mode > 9 || n0 < 1 || n0 > MAX_N || length != static_cast<std::size_t>(n0) + 3) return -1;
    const int n = static_cast<int>(n0);
    const auto *values = input + 3;
    if (mode == 0) {
        if (parameter != 0) return -1;
        for (int i = 0; i < n; ++i) if (values[i] < 0 || values[i] > 31) return -1;
    } else if (mode == 1) {
        if (parameter < 2 || parameter > 1000000) return -1;
        for (int i = 0; i < n; ++i) if (values[i] < 0 || values[i] >= parameter) return -1;
    } else if (mode == 2 || mode == 3) {
        if (parameter != 0) return -1;
        for (int i = 0; i < n; ++i) if (values[i] < 0 || values[i] > 1000000) return -1;
    } else if (mode == 4) {
        if (parameter < 1 || parameter > 128) return -1;
        for (int i = 0; i < n; ++i) if (values[i] < 0 || values[i] > 127) return -1;
    } else if (mode == 7) {
        if (parameter != 0) return -1;
        for (int i=0;i<n;++i) if (values[i]<0 || values[i]>1000000) return -1;
    } else if (mode == 8) {
        if (parameter != 0) return -1;
        for (int i=0;i<n;++i) if (values[i]<0 || values[i]>=(std::int64_t{1}<<28)) return -1;
    } else if (mode == 9) {
        if (parameter < 1 || parameter > 20) return -1;
        for (int i=0;i<n;++i) if (values[i]<0 || values[i]>1000000) return -1;
    } else {
        if (parameter < 2 || parameter > 4096 || n > parameter) return -1;
        for (int i = 0; i < n; ++i)
            if (values[i] < 0 || values[i] >= parameter || (i > 0 && values[i - 1] >= values[i])) return -1;
    }
    std::uint8_t staged[MAX_OUTPUT]{};
    std::size_t used = 0;
    if (mode == 0) for (int i = 0; i < n; ++i) unary(staged, used, static_cast<std::uint64_t>(values[i]));
    else if (mode == 1) for (int i = 0; i < n; ++i) minimal(staged, used, static_cast<std::uint64_t>(values[i]), static_cast<std::uint64_t>(parameter));
    else if (mode == 2) for (int i = 0; i < n; ++i) gamma(staged, used, static_cast<std::uint64_t>(values[i]));
    else if (mode == 3) for (int i = 0; i < n; ++i) delta(staged, used, static_cast<std::uint64_t>(values[i]));
    else if (mode == 4) {
        for (int i = 0; i < n; ++i) {
            const auto quotient = static_cast<std::uint64_t>(values[i] / parameter);
            const auto remainder = static_cast<std::uint64_t>(values[i] % parameter);
            unary(staged, used, quotient);
            minimal(staged, used, remainder, static_cast<std::uint64_t>(parameter));
        }
    } else if (mode == 5) {
        int width = 0;
        while (static_cast<std::uint64_t>(n) * (std::uint64_t{1} << (width + 1)) <= static_cast<std::uint64_t>(parameter)) ++width;
        const auto bucket_size = std::uint64_t{1} << width;
        const int buckets = static_cast<int>((static_cast<std::uint64_t>(parameter) + bucket_size - 1) / bucket_size);
        std::uint8_t counts[4096]{};
        for (int i = 0; i < n; ++i) ++counts[static_cast<std::uint64_t>(values[i]) / bucket_size];
        for (int bucket = 0; bucket < buckets; ++bucket) unary(staged, used, counts[bucket]);
        for (int i = 0; i < n; ++i) number(staged, used, static_cast<std::uint64_t>(values[i]) % bucket_size, width);
    } else if (mode == 6) interpolative(staged, used, values, 0, n, 0, parameter);
    else if (mode == 7) {
        for (int i=0;i<n;++i) {
            const auto value=static_cast<std::uint64_t>(values[i]);
            int highest=floor_log2(value);
            highest=highest<0?0:(highest/7)*7;
            for (int shift=highest;shift>=0;shift-=7) {
                auto byte=static_cast<std::uint8_t>((value>>shift)&0x7Fu);
                if (shift!=0) byte|=0x80u;
                raw_byte(staged,used,byte);
            }
        }
    } else if (mode == 8) simple9(staged, used, values, n);
    else {
        const int width=static_cast<int>(parameter);
        const auto low_mask=(std::uint64_t{1}<<width)-1;
        int exception_count=0;
        for (int i=0;i<n;++i) {
            number(staged,used,static_cast<std::uint64_t>(values[i])&low_mask,width);
            if (static_cast<std::uint64_t>(values[i]) >= (std::uint64_t{1}<<width)) ++exception_count;
        }
        number(staged,used,static_cast<std::uint64_t>(exception_count),6);
        int position_width=0;while ((1<<position_width)<n) ++position_width;
        for (int i=0;i<n;++i) if (static_cast<std::uint64_t>(values[i]) >= (std::uint64_t{1}<<width)) {
            number(staged,used,static_cast<std::uint64_t>(i),position_width);
            number(staged,used,static_cast<std::uint64_t>(values[i]),20);
        }
    }
    if (!output) return -2;
    if (mode == 7) {
        if (capacity < used) return -2;
        for (std::size_t i=0;i<used;++i) output[i]=staged[i];
        return static_cast<std::int64_t>(used);
    }
    const std::size_t bytes=(used+7)/8;
    if (capacity<bytes) return -2;
    std::uint8_t packed[MAX_RESULT]{};
    for (std::size_t i=0;i<used;++i)
        if (staged[i]=='1') packed[i/8] |= static_cast<std::uint8_t>(1u << (7-(i%8)));
    for (std::size_t i=0;i<bytes;++i) output[i]=packed[i];
    return static_cast<std::int64_t>(bytes);
}
