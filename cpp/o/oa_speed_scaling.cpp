#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_jobs = 2, max_input = 8, max_segments = 3;
constexpr std::size_t max_output_bytes = 152, max_output_values = 19;
struct Rat { std::int64_t n, d; };
struct Segment { std::int64_t start, end, speed_n, speed_d; };

std::int64_t gcd64(std::int64_t a, std::int64_t b) {
    while (b != 0) { const auto r = a % b; a = b; b = r; }
    return a < 0 ? -a : a;
}
Rat make(std::int64_t n, std::int64_t d) {
    if (d < 0) { n = -n; d = -d; }
    const auto g = gcd64(n, d);
    return {n / g, d / g};
}
Rat add(Rat a, Rat b) { return make(a.n*b.d + b.n*a.d, a.d*b.d); }
Rat sub(Rat a, Rat b) { return make(a.n*b.d - b.n*a.d, a.d*b.d); }
Rat mul(Rat a, Rat b) { return make(a.n*b.n, a.d*b.d); }
Rat div(Rat a, Rat b) { return make(a.n*b.d, a.d*b.n); }
Rat integer(std::int64_t x) { return {x, 1}; }
int compare(Rat a, Rat b) {
    const auto x = a.n*b.d, y = b.n*a.d;
    return (x > y) - (x < y);
}
void store(std::uint8_t* output, std::size_t at, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b)
        output[at+b] = static_cast<std::uint8_t>(bits >> (8*b));
}
void append_segment(std::array<Segment,max_segments>& segments,
                    std::size_t& count, std::int64_t start,
                    std::int64_t end, Rat speed) {
    if (end <= start || speed.n <= 0) return;
    if (count && segments[count-1].end == start &&
        compare(speed, make(segments[count-1].speed_n,
                            segments[count-1].speed_d)) == 0) {
        segments[count-1].end = end;
        return;
    }
    segments[count++] = {start,end,speed.n,speed.d};
}
}

extern "C" std::int64_t oa_speed_scaling(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > max_input) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_jobs) ||
        length != 1 + 3*static_cast<std::size_t>(input[0])) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    std::array<std::int64_t,max_jobs> release{}, deadline{};
    std::array<Rat,max_jobs> remaining{{{0,1},{0,1}}}, completion{{{0,1},{0,1}}};
    std::array<bool,max_jobs> completed{};
    for (std::size_t j = 0; j < n; ++j) {
        release[j] = input[1+3*j]; deadline[j] = input[2+3*j];
        const auto work = input[3+3*j];
        if (release[j] < 0 || release[j] >= deadline[j] || deadline[j] > 4 ||
            work < 1 || work > 4) return -1;
    }

    std::array<Segment,max_segments> segments{};
    std::size_t segment_count = 0;
    Rat energy = integer(0);
    for (std::int64_t now = 0; now <= 4; ++now) {
        bool has_arrival = false;
        for (std::size_t j = 0; j < n; ++j) if (release[j] == now) {
            remaining[j] = integer(input[3+3*j]); has_arrival = true;
        }
        if (!has_arrival) continue;
        std::int64_t next_release = 5;
        for (std::size_t j = 0; j < n; ++j)
            if (release[j] > now && release[j] < next_release) next_release = release[j];

        std::array<int,max_jobs> order{};
        int count = 0;
        for (std::size_t j = 0; j < n; ++j)
            if (remaining[j].n > 0 && deadline[j] > now) order[count++] = static_cast<int>(j);
        for (int i = 1; i < count; ++i) {
            const int value = order[i]; int k = i;
            while (k > 0 && (deadline[order[k-1]] > deadline[value] ||
                   (deadline[order[k-1]] == deadline[value] && order[k-1] > value))) {
                order[k] = order[k-1]; --k;
            }
            order[k] = value;
        }
        std::int64_t left = now;
        while (count > 0) {
            Rat prefix = integer(0), best = integer(0);
            int best_count = 0;
            for (int k = 1; k <= count; ++k) {
                prefix = add(prefix, remaining[order[k-1]]);
                const Rat density = div(prefix, integer(deadline[order[k-1]]-left));
                if (best_count == 0 || compare(density,best) > 0) {
                    best = density; best_count = k;
                }
            }
            const auto right = deadline[order[best_count-1]];
            const auto stop = right < next_release ? right : next_release;
            append_segment(segments,segment_count,left,stop,best);
            energy = add(energy,mul(mul(mul(best,best),best),integer(stop-left)));
            Rat cursor = integer(left), stop_rat = integer(stop);
            for (int k = 0; k < best_count; ++k) {
                const int j = order[k];
                if (remaining[j].n <= 0) continue;
                const Rat finish = add(cursor,div(remaining[j],best));
                if (compare(finish,stop_rat) <= 0) {
                    completion[j] = finish; completed[j] = true;
                    remaining[j] = integer(0); cursor = finish;
                } else {
                    remaining[j] = sub(remaining[j],mul(best,sub(stop_rat,cursor)));
                    cursor = stop_rat;
                    break;
                }
            }
            if (stop < right) break;
            for (int k = best_count; k < count; ++k) order[k-best_count] = order[k];
            count -= best_count; left = right;
        }
    }
    for (std::size_t j = 0; j < n; ++j) if (!completed[j]) return -1;
    std::array<std::int64_t,max_output_values> values{};
    std::size_t fields = 0;
    values[fields++] = static_cast<std::int64_t>(segment_count);
    values[fields++] = energy.n; values[fields++] = energy.d;
    for (std::size_t i = 0; i < segment_count; ++i) {
        values[fields++] = segments[i].start; values[fields++] = segments[i].end;
        values[fields++] = segments[i].speed_n; values[fields++] = segments[i].speed_d;
    }
    for (std::size_t j = 0; j < n; ++j) {
        values[fields++] = completion[j].n; values[fields++] = completion[j].d;
    }
    const auto bytes = 8*fields;
    if (output == nullptr || capacity < bytes) return -2;
    std::array<std::uint8_t,max_output_bytes> staged{};
    for (std::size_t i = 0; i < fields; ++i) store(staged.data(),8*i,values[i]);
    for (std::size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(bytes);
}
