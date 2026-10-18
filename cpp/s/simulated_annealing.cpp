#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_PACKED_LENGTH = 366;
constexpr std::int64_t MAX_DRAWS = 176;
constexpr std::int64_t MAX_ITERATIONS = 22;
constexpr std::int64_t INVALID_RESULT = -1;

std::int64_t score_i64(std::int64_t x, std::int64_t y) noexcept
{
    return x * x + y * y;
}
}

extern "C" std::int64_t simulated_annealing(const std::int64_t *packed, std::size_t length) noexcept
{
    if (packed == nullptr || length < 13 || length > MAX_PACKED_LENGTH) return INVALID_RESULT;
    const auto x0=packed[0], y0=packed[1], step=packed[2];
    const auto min_x=packed[3], max_x=packed[4], min_y=packed[5], max_y=packed[6];
    const auto find_max=packed[7], start_raw=packed[8], rate_raw=packed[9], threshold_raw=packed[10];
    const auto selection_count=packed[11];
    if (x0 < -16 || x0 > 16 || y0 < -16 || y0 > 16 || step < 1 || step > 4 ||
        min_x < -16 || max_x > 16 || min_x > max_x || min_y < -16 || max_y > 16 || min_y > max_y ||
        x0 < min_x || x0 > max_x || y0 < min_y || y0 > max_y || (find_max != 0 && find_max != 1) ||
        start_raw < 1000000 || start_raw > 10000000 || rate_raw < 100000 || rate_raw > 500000 ||
        threshold_raw < 1000000 || threshold_raw > 9999999 || threshold_raw >= start_raw ||
        selection_count < 0 || selection_count > MAX_DRAWS ||
        static_cast<std::size_t>(selection_count) > length - 13) return INVALID_RESULT;

    const auto selection_n = static_cast<std::size_t>(selection_count);
    const auto acceptance_count_index = 12 + selection_n;
    const auto acceptance_count = packed[acceptance_count_index];
    if (acceptance_count < 0 || acceptance_count > MAX_DRAWS ||
        length != 13 + selection_n + static_cast<std::size_t>(acceptance_count)) return INVALID_RESULT;
    for (std::size_t i=0; i<selection_n; ++i) if (packed[12+i] < 0 || packed[12+i] > 7) return INVALID_RESULT;
    const auto acceptance_start = acceptance_count_index + 1;
    for (std::size_t i=0; i<static_cast<std::size_t>(acceptance_count); ++i) {
        const auto draw=packed[acceptance_start+i];
        if (draw != 0 && draw != 999999) return INVALID_RESULT;
    }

    double current_temp=static_cast<double>(start_raw)/1000000.0;
    const double rate=static_cast<double>(rate_raw)/1000000.0;
    const double threshold=static_cast<double>(threshold_raw)/1000000.0;
    auto current_x=x0, current_y=y0, best_x=x0, best_y=y0;
    auto best_score=score_i64(x0,y0);
    std::size_t selection_cursor=0, acceptance_cursor=0;
    bool stopped=false;
    for (std::int64_t iteration=0; iteration<MAX_ITERATIONS; ++iteration) {
        const auto current_score=score_i64(current_x,current_y);
        if (current_score>best_score) { best_score=current_score; best_x=current_x; best_y=current_y; }
        std::int64_t nx[8]={current_x-step,current_x-step,current_x-step,current_x,current_x,current_x+step,current_x+step,current_x+step};
        std::int64_t ny[8]={current_y-step,current_y,current_y+step,current_y-step,current_y+step,current_y-step,current_y,current_y+step};
        std::size_t remaining=8;
        bool found=false;
        std::int64_t next_x=0,next_y=0;
        while (!found && remaining>0) {
            if (selection_cursor>=selection_n) return INVALID_RESULT;
            const auto rank=packed[12+selection_cursor++];
            if (static_cast<std::size_t>(rank)>=remaining) return INVALID_RESULT;
            const auto selected=static_cast<std::size_t>(rank);
            const auto candidate_x=nx[selected],candidate_y=ny[selected];
            const auto raw_change=score_i64(candidate_x,candidate_y)-current_score;
            for (std::size_t i=selected+1;i<remaining;++i) { nx[i-1]=nx[i]; ny[i-1]=ny[i]; }
            --remaining;
            if (candidate_x<min_x||candidate_x>max_x||candidate_y<min_y||candidate_y>max_y) continue;
            const auto change=find_max?raw_change:-raw_change;
            if (change>0) found=true;
            else {
                if (acceptance_cursor>=static_cast<std::size_t>(acceptance_count)) return INVALID_RESULT;
                const auto draw=packed[acceptance_start+acceptance_cursor++];
                if (change==0||draw==0) found=true;
            }
            if (found) { next_x=candidate_x; next_y=candidate_y; }
        }
        current_temp=current_temp-current_temp*rate;
        if (current_temp<threshold||!found) { stopped=true; break; }
        current_x=next_x; current_y=next_y;
    }
    if (!stopped) return INVALID_RESULT;
    return (best_x+16)*33+(best_y+16);
}
