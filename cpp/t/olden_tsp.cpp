#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxCities = 7;
constexpr int kConquerThreshold = 3;
constexpr double kScale = 1000.0;

double distance(const std::int64_t *x, const std::int64_t *y, int a, int b) {
    const double dx = static_cast<double>(x[a] - x[b]);
    const double dy = static_cast<double>(y[a] - y[b]);
    return std::sqrt(dx * dx + dy * dy);
}

int subtree_size(int node, int count) {
    if (node >= count) return 0;
    return 1 + subtree_size(2 * node + 1, count) + subtree_size(2 * node + 2, count);
}

void collect_postorder(int node, int count, int *order, int &length) {
    if (node >= count) return;
    collect_postorder(2 * node + 1, count, order, length);
    collect_postorder(2 * node + 2, count, order, length);
    order[length++] = node;
}

void reverse_cycle(int start, int size, int *next, int *prev) {
    int current = start;
    for (int i = 0; i < size; ++i) {
        const int old_next = next[current];
        const int old_prev = prev[current];
        next[current] = old_prev;
        prev[current] = old_next;
        current = old_next;
    }
}

int conquer(const int *order, int count, const std::int64_t *x, const std::int64_t *y,
            int *next, int *prev) {
    const int cycle = order[0];
    next[cycle] = prev[cycle] = cycle;
    for (int index = 1; index < count; ++index) {
        const int point = order[index];
        int min = cycle;
        double mindist = distance(x, y, point, cycle);
        for (int tmp = next[cycle]; tmp != cycle; tmp = next[tmp]) {
            const double test = distance(x, y, tmp, point);
            if (test < mindist) { mindist = test; min = tmp; }
        }
        const int next_city = next[min], prev_city = prev[min];
        const double min_to_next = distance(x, y, min, next_city);
        const double min_to_prev = distance(x, y, min, prev_city);
        const double point_to_next = distance(x, y, point, next_city);
        const double point_to_prev = distance(x, y, point, prev_city);
        if (point_to_prev - min_to_prev < point_to_next - min_to_next) {
            next[prev_city] = point; prev[point] = prev_city;
            next[point] = min; prev[min] = point;
        } else {
            prev[next_city] = point; next[point] = next_city;
            next[min] = point; prev[point] = min;
        }
    }
    return cycle;
}

int merge_cycles(int a, int b, int point, int size_a, int size_b,
                 const std::int64_t *x, const std::int64_t *y, int *next, int *prev) {
    int min = a;
    double mindist = distance(x, y, point, a);
    for (int tmp = next[a]; tmp != a; tmp = next[tmp]) {
        const double test = distance(x, y, point, tmp);
        if (test < mindist) { mindist = test; min = tmp; }
    }
    int next_city = next[min], prev_city = prev[min];
    double min_to_next = distance(x, y, min, next_city);
    double min_to_prev = distance(x, y, min, prev_city);
    double point_to_next = distance(x, y, point, next_city);
    double point_to_prev = distance(x, y, point, prev_city);
    int n1, p1;
    double tton1, ttop1;
    if (point_to_prev - min_to_prev < point_to_next - min_to_next) {
        p1 = prev_city; n1 = min; tton1 = mindist; ttop1 = point_to_prev;
    } else {
        p1 = min; n1 = next_city; ttop1 = mindist; tton1 = point_to_next;
    }

    min = b;
    mindist = distance(x, y, point, b);
    for (int tmp = next[b]; tmp != b; tmp = next[tmp]) {
        const double test = distance(x, y, point, tmp);
        if (test < mindist) { mindist = test; min = tmp; }
    }
    next_city = next[min]; prev_city = prev[min];
    min_to_next = distance(x, y, min, next_city);
    min_to_prev = distance(x, y, min, prev_city);
    point_to_next = distance(x, y, point, next_city);
    point_to_prev = distance(x, y, point, prev_city);
    int n2, p2;
    double tton2, ttop2;
    if (point_to_prev - min_to_prev < point_to_next - min_to_next) {
        p2 = prev_city; n2 = min; tton2 = mindist; ttop2 = point_to_prev;
    } else {
        p2 = min; n2 = next_city; ttop2 = mindist; tton2 = point_to_next;
    }

    const double n1_to_n2 = distance(x, y, n1, n2);
    const double n1_to_p2 = distance(x, y, n1, p2);
    const double p1_to_n2 = distance(x, y, p1, n2);
    const double p1_to_p2 = distance(x, y, p1, p2);
    double best = ttop1 + ttop2 + n1_to_n2;
    int choice = 1;
    double test = ttop1 + tton2 + n1_to_p2;
    if (test < best) { choice = 2; best = test; }
    test = tton1 + ttop2 + p1_to_n2;
    if (test < best) { choice = 3; best = test; }
    test = tton1 + tton2 + p1_to_p2;
    if (test < best) choice = 4;

    if (choice == 1) {
        reverse_cycle(n2, size_b, next, prev);
        next[p1] = point; prev[point] = p1; next[point] = p2; prev[p2] = point;
        next[n2] = n1; prev[n1] = n2;
    } else if (choice == 2) {
        next[p1] = point; prev[point] = p1; next[point] = n2; prev[n2] = point;
        next[p2] = n1; prev[n1] = p2;
    } else if (choice == 3) {
        next[p2] = point; prev[point] = p2; next[point] = n1; prev[n1] = point;
        next[p1] = n2; prev[n2] = p1;
    } else {
        reverse_cycle(n1, size_a, next, prev);
        next[n1] = point; prev[point] = n1; next[point] = n2; prev[n2] = point;
        next[p2] = p1; prev[p1] = p2;
    }
    return point;
}

int solve_subtree(int node, int count, const std::int64_t *x, const std::int64_t *y,
                  int *next, int *prev) {
    const int size = subtree_size(node, count);
    if (size <= kConquerThreshold) {
        int order[kMaxCities], order_count = 0;
        collect_postorder(node, count, order, order_count);
        return conquer(order, order_count, x, y, next, prev);
    }
    const int left = 2 * node + 1, right = 2 * node + 2;
    const int left_cycle = solve_subtree(left, count, x, y, next, prev);
    const int right_cycle = solve_subtree(right, count, x, y, next, prev);
    return merge_cycles(left_cycle, right_cycle, node, subtree_size(left, count),
                        subtree_size(right, count), x, y, next, prev);
}
}

extern "C" std::int64_t olden_tsp(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || (length != 7 && length != 15)) return -1;
    const std::int64_t count_value = input[0];
    if (count_value != 3 && count_value != 7) return -1;
    const int count = static_cast<int>(count_value);
    if (length != static_cast<std::size_t>(1 + 2 * count)) return -1;
    std::int64_t x[kMaxCities], y[kMaxCities];
    int next[kMaxCities] = {}, prev[kMaxCities] = {};
    for (int city = 0; city < count; ++city) {
        x[city] = input[1 + 2 * city];
        y[city] = input[2 + 2 * city];
        if (x[city] < -8 || x[city] > 8 || y[city] < -8 || y[city] > 8) return -1;
    }
    solve_subtree(0, count, x, y, next, prev);
    double tour_length = 0.0;
    int city = 0;
    for (int edge = 0; edge < count; ++edge) {
        const int following = next[city];
        tour_length += distance(x, y, city, following);
        city = following;
    }
    return static_cast<std::int64_t>(std::floor(tour_length * kScale + 0.5));
}
