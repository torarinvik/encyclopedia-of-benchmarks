#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr int max_leaves = 4;
struct Combination { std::int64_t left, right; int operation; };
struct Search {
    int count = 0, depth_limit = 0, best_depth = 0;
    bool stopped = false;
    std::int64_t goal = 0, best = 0;
    std::int64_t work[2 * max_leaves]{};
    Combination current[max_leaves]{}, saved[max_leaves]{};
};
std::int64_t distance_from(std::int64_t a, std::int64_t b) { return a >= b ? a - b : b - a; }
std::int64_t apply(std::int64_t a, std::int64_t b, int op) {
    switch (op) { case 1: return a + b; case 2: return a - b; case 3: return a * b; default: return a / b; }
}
void search(Search& s, int depth, std::uint32_t used) {
    if (s.stopped) return;
    if (depth == s.depth_limit) {
        const auto candidate = s.work[s.count + depth - 1];
        if (distance_from(candidate, s.goal) < distance_from(s.best, s.goal)) {
            s.best = candidate;
            s.best_depth = depth;
            for (int i = 0; i < depth; ++i) s.saved[i] = s.current[i];
            if (s.best == s.goal) s.stopped = true;
        }
        return;
    }
    for (int op = 1; op <= 4 && !s.stopped; ++op) {
        for (int first = 0; first < s.count + depth && !s.stopped; ++first) {
            if (used & (std::uint32_t{1} << first)) continue;
            for (int second = 0; second < first && !s.stopped; ++second) {
                if (used & (std::uint32_t{1} << second)) continue;
                auto left = s.work[first], right = s.work[second];
                if ((op == 3 || op == 4) && (left == 1 || right == 1)) continue;
                if (left == 0 || right == 0) continue;
                if (op == 4 && left % right != 0) continue;
                if ((op == 2 || op == 4) && left < right) std::swap(left, right);
                s.current[depth] = {left, right, op};
                s.work[s.count + depth] = apply(left, right, op);
                search(s, depth + 1, used | (std::uint32_t{1} << first) | (std::uint32_t{1} << second));
            }
        }
    }
}
}

extern "C" std::int64_t mcgill_exptree(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 3 || length > 6) return -1;
    const auto goal = input[0], raw_count = input[1];
    if (goal < 1 || goal > 1000000000 || raw_count < 1 || raw_count > max_leaves ||
        length != static_cast<std::size_t>(raw_count + 2)) return -1;
    Search s;
    s.count = static_cast<int>(raw_count);
    s.goal = goal;
    for (int i = 0; i < s.count; ++i) {
        const auto value = input[2 + i];
        if (value < 1 || value > 100) return -1;
        s.work[i] = value;
    }
    for (int i = 0; i < s.count; ++i)
        if (distance_from(s.work[i], s.goal) < distance_from(s.best, s.goal)) s.best = s.work[i];
    if (s.best == s.goal) return s.best;
    for (s.depth_limit = 1; s.depth_limit < s.count; ++s.depth_limit) {
        search(s, 0, 0);
        if (s.stopped) break;
    }
    return s.best;
}
