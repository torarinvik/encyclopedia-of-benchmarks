#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 64;
constexpr std::size_t max_length = 194;

struct Point {
    std::int64_t x, y, z, multiplicity, z_rank, original_index;
};

struct Workspace {
    Point points[max_n]{};
    std::int64_t original_group[max_n]{};
    std::int64_t dominated[max_n]{};
    std::int64_t bit[max_n + 1]{};
    std::int64_t source_order[max_n]{};
    std::int64_t target_order[max_n]{};
    std::int64_t z_values[max_n]{};
};

bool point_less(const Point& a, const Point& b) {
    if (a.x != b.x) return a.x < b.x;
    if (a.y != b.y) return a.y < b.y;
    return a.z < b.z;
}

bool same_coordinates(const Point& a, const Point& b) {
    return a.x == b.x && a.y == b.y && a.z == b.z;
}

void bit_add(Workspace& work, std::size_t index, std::int64_t delta,
             std::size_t limit) {
    while (index <= limit) {
        work.bit[index] += delta;
        index += index & (0 - index);
    }
}

std::int64_t bit_sum(const Workspace& work, std::size_t index) {
    std::int64_t sum = 0;
    while (index > 0) {
        sum += work.bit[index];
        index -= index & (0 - index);
    }
    return sum;
}

void cdq(Workspace& work, std::size_t left, std::size_t right,
         std::size_t group_count) {
    if (left >= right) return;
    const auto middle = left + (right - left) / 2;
    cdq(work, left, middle, group_count);
    cdq(work, middle + 1, right, group_count);

    std::size_t source_cursor = left;
    for (std::size_t target_position = middle + 1; target_position <= right; ++target_position) {
        const auto target = static_cast<std::size_t>(work.source_order[target_position]);
        while (source_cursor <= middle) {
            const auto source = static_cast<std::size_t>(work.source_order[source_cursor]);
            if (work.points[source].y > work.points[target].y) break;
            bit_add(work, static_cast<std::size_t>(work.points[source].z_rank),
                    work.points[source].multiplicity, group_count);
            ++source_cursor;
        }
        work.dominated[target] += bit_sum(work, static_cast<std::size_t>(work.points[target].z_rank));
    }
    for (std::size_t i = left; i < source_cursor; ++i) {
        const auto source = static_cast<std::size_t>(work.source_order[i]);
        bit_add(work, static_cast<std::size_t>(work.points[source].z_rank),
                -work.points[source].multiplicity, group_count);
    }

    auto left_cursor = left;
    auto right_cursor = middle + 1;
    auto destination = left;
    while (left_cursor <= middle && right_cursor <= right) {
        const auto left_point = static_cast<std::size_t>(work.source_order[left_cursor]);
        const auto right_point = static_cast<std::size_t>(work.source_order[right_cursor]);
        if (work.points[left_point].y <= work.points[right_point].y)
            work.target_order[destination++] = work.source_order[left_cursor++];
        else
            work.target_order[destination++] = work.source_order[right_cursor++];
    }
    while (left_cursor <= middle) work.target_order[destination++] = work.source_order[left_cursor++];
    while (right_cursor <= right) work.target_order[destination++] = work.source_order[right_cursor++];
    for (std::size_t i = left; i <= right; ++i) work.source_order[i] = work.target_order[i];
}

std::int64_t solve(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 1 || length > max_length) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_n)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + 3 * n) return -1;

    Workspace work{};
    for (std::size_t i = 0; i < n; ++i) {
        const auto x = input[1 + 3 * i];
        const auto y = input[2 + 3 * i];
        const auto z = input[3 + 3 * i];
        if (x < -1000 || x > 1000 || y < -1000 || y > 1000 || z < -1000 || z > 1000)
            return -1;
        work.points[i] = Point{x, y, z, 1, 0, static_cast<std::int64_t>(i)};
    }
    for (std::size_t i = 1; i < n; ++i) {
        const auto value = work.points[i];
        auto j = i;
        while (j > 0 && point_less(value, work.points[j - 1])) {
            work.points[j] = work.points[j - 1];
            --j;
        }
        work.points[j] = value;
    }

    std::size_t group_count = 0;
    for (std::size_t i = 0; i < n; ++i) {
        if (group_count > 0 && same_coordinates(work.points[i], work.points[group_count - 1])) {
            ++work.points[group_count - 1].multiplicity;
            work.original_group[static_cast<std::size_t>(work.points[i].original_index)] =
                static_cast<std::int64_t>(group_count - 1);
        } else {
            work.points[group_count] = work.points[i];
            work.points[group_count].multiplicity = 1;
            work.original_group[static_cast<std::size_t>(work.points[group_count].original_index)] =
                static_cast<std::int64_t>(group_count);
            ++group_count;
        }
    }

    for (std::size_t i = 0; i < group_count; ++i) work.z_values[i] = work.points[i].z;
    for (std::size_t i = 1; i < group_count; ++i) {
        const auto value = work.z_values[i];
        auto j = i;
        while (j > 0 && value < work.z_values[j - 1]) {
            work.z_values[j] = work.z_values[j - 1];
            --j;
        }
        work.z_values[j] = value;
    }
    std::size_t z_count = 0;
    for (std::size_t i = 0; i < group_count; ++i) {
        if (z_count == 0 || work.z_values[i] != work.z_values[z_count - 1])
            work.z_values[z_count++] = work.z_values[i];
    }
    for (std::size_t i = 0; i < group_count; ++i) {
        std::size_t low = 0, high = z_count;
        while (low < high) {
            const auto middle = low + (high - low) / 2;
            if (work.z_values[middle] < work.points[i].z) low = middle + 1;
            else high = middle;
        }
        work.points[i].z_rank = static_cast<std::int64_t>(low + 1);
        work.source_order[i] = i;
    }

    if (group_count > 1) cdq(work, 0, group_count - 1, z_count);
    std::int64_t result = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const auto group = static_cast<std::size_t>(work.original_group[i]);
        const auto count = work.dominated[group] + work.points[group].multiplicity - 1;
        result += static_cast<std::int64_t>(i + 1) * count;
    }
    return result;
}
}  // namespace

extern "C" std::int64_t cdq_three_dimensional_dominance(
    const std::int64_t* input, std::size_t length) noexcept {
    return solve(input, length);
}
