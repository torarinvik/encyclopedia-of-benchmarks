#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 8, MAX_INPUT = 84, OUTPUT_VALUES = 10, MAX_OUTPUT = 80;
void put64(std::uint8_t* output, std::size_t position, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[position + byte] = static_cast<std::uint8_t>(bits >> (8U * byte));
}
bool angle_better(std::int64_t da, std::int64_t la, std::int64_t db, std::int64_t lb) {
    if ((da >= 0) != (db >= 0)) return da >= 0;
    auto left = da * da * lb, right = db * db * la;
    return da >= 0 ? left > right : left < right;
}
bool angle_equal(std::int64_t da, std::int64_t la, std::int64_t db, std::int64_t lb) {
    return (da >= 0) == (db >= 0) && da * da * lb == db * db * la;
}
}

extern "C" std::int64_t geometric_greedy_compass_routing(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 12 || length > MAX_INPUT) return -1;
    auto n64 = input[0], mode = input[1], source64 = input[2], target64 = input[3];
    if (n64 < 2 || n64 > MAX_N || mode < 0 || mode > 1 || source64 < 0 || target64 < 0 || source64 >= n64 || target64 >= n64) return -1;
    auto n = static_cast<std::size_t>(n64), source = static_cast<std::size_t>(source64), target = static_cast<std::size_t>(target64);
    if (length != 4 + 2*n + n*n) return -1;
    std::int64_t x[MAX_N]{}, y[MAX_N]{};
    auto adjacency = 4 + 2*n;
    for (std::size_t i = 0; i < n; ++i) {
        x[i] = input[4+i]; y[i] = input[4+n+i];
        if (x[i] < -8 || x[i] > 8 || y[i] < -8 || y[i] > 8) return -1;
        for (std::size_t j = 0; j < i; ++j) if (x[i] == x[j] && y[i] == y[j]) return -1;
    }
    for (std::size_t i = 0; i < n; ++i) for (std::size_t j = 0; j < n; ++j) {
        auto a = input[adjacency+i*n+j], b = input[adjacency+j*n+i];
        if ((a != 0 && a != 1) || a != b || (i == j && a != 0)) return -1;
    }
    if (output == nullptr || capacity < MAX_OUTPUT) return -2;
    std::size_t path[MAX_N], count = 1; bool visited[MAX_N]{};
    path[0] = source; visited[source] = true; auto current = source;
    while (current != target && count < n) {
        std::size_t best = n; std::int64_t best_dot = 0, best_len = 1, best_distance = 0;
        auto tx = x[target]-x[current], ty = y[target]-y[current];
        for (std::size_t v = 0; v < n; ++v) {
            if (input[adjacency+current*n+v] != 1) continue;
            bool better = best == n;
            auto dx = x[v]-x[current], dy = y[v]-y[current];
            if (mode == 0) {
                auto rx = x[v]-x[target], ry = y[v]-y[target]; auto distance = rx*rx+ry*ry;
                if (!better) better = distance < best_distance || (distance == best_distance && v < best);
                if (better) best_distance = distance;
            } else {
                auto dot = dx*tx+dy*ty, len = dx*dx+dy*dy;
                if (!better) better = angle_better(dot,len,best_dot,best_len) || (angle_equal(dot,len,best_dot,best_len) && v < best);
                if (better) { best_dot = dot; best_len = len; }
            }
            if (better) best = v;
        }
        if (best == n || visited[best]) break;
        path[count++] = best; visited[best] = true; current = best;
    }
    std::int64_t record[OUTPUT_VALUES]{};
    record[0] = current == target ? 1 : 0; record[1] = static_cast<std::int64_t>(count-1);
    for (std::size_t i = 0; i < MAX_N; ++i) record[2+i] = -1;
    for (std::size_t i = 0; i < count; ++i) record[2+i] = static_cast<std::int64_t>(path[i]);
    std::uint8_t staged[MAX_OUTPUT]{};
    for (std::size_t i = 0; i < OUTPUT_VALUES; ++i) put64(staged,8*i,record[i]);
    for (std::size_t i = 0; i < MAX_OUTPUT; ++i) output[i] = staged[i];
    return MAX_OUTPUT;
}
