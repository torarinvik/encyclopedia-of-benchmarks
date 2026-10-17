#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_POINTS 15
#define MAX_DIMENSION 3
#define INVALID_RESULT (-1)
#define OUTPUT_ERROR (-2)

typedef struct { size_t point, left, right; int axis; } node;
typedef struct {
    const double (*points)[MAX_DIMENSION];
    size_t dimension, used, ids[MAX_POINTS];
    node nodes[MAX_POINTS];
} build_context;

static size_t partition_five(build_context *ctx, size_t from, size_t to, size_t axis)
{
    const size_t middle = (from + to) / 2;
    for (size_t i = from; i <= middle; ++i) {
        size_t minimum = i;
        for (size_t j = i + 1; j <= to; ++j)
            if (ctx->points[ctx->ids[j]][axis] < ctx->points[ctx->ids[minimum]][axis]) minimum = j;
        const size_t temporary = ctx->ids[i];
        ctx->ids[i] = ctx->ids[minimum];
        ctx->ids[minimum] = temporary;
    }
    return middle;
}

static size_t select_kth(build_context *ctx, size_t from, size_t to, size_t rank, size_t axis);

static size_t choose_median_of_medians(build_context *ctx, size_t from, size_t to, size_t axis)
{
    if (to - from < 5) return partition_five(ctx, from, to, axis);
    size_t medians_to = from;
    for (size_t start = from; start <= to - 4; start += 5) {
        const size_t median = partition_five(ctx, start, start + 4, axis);
        const size_t temporary = ctx->ids[median];
        ctx->ids[median] = ctx->ids[medians_to];
        ctx->ids[medians_to] = temporary;
        ++medians_to;
    }
    const size_t remainder = (to - from + 1) % 5;
    if (remainder == 0) {
        --medians_to;
    } else {
        const size_t median = partition_five(ctx, to - remainder + 1, to, axis);
        const size_t temporary = ctx->ids[median];
        ctx->ids[median] = ctx->ids[medians_to];
        ctx->ids[medians_to] = temporary;
    }
    const size_t medians_count = medians_to - from + 1;
    return select_kth(ctx, from, medians_to, (medians_count + 1) / 2, axis);
}

static void partition_three_way(build_context *ctx, size_t from, size_t to, size_t pivot_index,
                                size_t axis, size_t *smaller_to, size_t *larger_from)
{
    const double pivot = ctx->points[ctx->ids[pivot_index]][axis];
    size_t i = from, j = from, k = to;
    while (j <= k) {
        const double value = ctx->points[ctx->ids[j]][axis];
        if (value < pivot) {
            const size_t temporary = ctx->ids[i]; ctx->ids[i] = ctx->ids[j]; ctx->ids[j] = temporary;
            ++i; ++j;
        } else if (pivot < value) {
            const size_t temporary = ctx->ids[j]; ctx->ids[j] = ctx->ids[k]; ctx->ids[k] = temporary;
            if (k == 0) break;
            --k;
        } else {
            ++j;
        }
    }
    *smaller_to = i == 0 ? 0 : i - 1;
    *larger_from = k + 1;
}

static size_t select_kth(build_context *ctx, size_t from, size_t to, size_t rank, size_t axis)
{
    while (from < to) {
        const size_t pivot_index = choose_median_of_medians(ctx, from, to, axis);
        size_t smaller_to, larger_from;
        partition_three_way(ctx, from, to, pivot_index, axis, &smaller_to, &larger_from);
        const size_t absolute_index = from + rank - 1;
        if (absolute_index <= smaller_to) {
            to = smaller_to;
        } else if (absolute_index < larger_from) {
            return absolute_index;
        } else {
            const size_t smaller_or_equal_count = larger_from - from;
            rank -= smaller_or_equal_count;
            from = larger_from;
        }
    }
    return from;
}

static size_t build_tree(build_context *ctx, size_t from, size_t to, size_t depth)
{
    if (from > to) return SIZE_MAX;
    const size_t axis = depth % ctx->dimension;
    const size_t count = to - from + 1;
    const size_t middle = select_kth(ctx, from, to, (count + 1) / 2, axis);
    const size_t current = ctx->used++;
    ctx->nodes[current].point = ctx->ids[middle];
    ctx->nodes[current].axis = (int)axis;
    ctx->nodes[current].left = middle > from
        ? build_tree(ctx, from, middle - 1, depth + 1) : SIZE_MAX;
    ctx->nodes[current].right = middle < to
        ? build_tree(ctx, middle + 1, to, depth + 1) : SIZE_MAX;
    return current;
}

static void search_tree(const build_context *ctx, size_t current, size_t axis,
                        const double query[MAX_DIMENSION], double *best,
                        size_t *best_point)
{
    if (current == SIZE_MAX) return;
    const node *entry = &ctx->nodes[current];
    const double *point = ctx->points[entry->point];
    double squared = 0.0;
    for (size_t a = 0; a < ctx->dimension; ++a) {
        const double delta = query[a] - point[a];
        squared += delta * delta;
    }
    const double distance = sqrt(squared);
    if (distance < *best) { *best = distance; *best_point = entry->point; }
    const int go_left = query[axis] <= point[axis];
    const size_t near = go_left ? entry->left : entry->right;
    const size_t far = go_left ? entry->right : entry->left;
    const size_t next_axis = (axis + 1) % ctx->dimension;
    search_tree(ctx, near, next_axis, query, best, best_point);
    if (*best >= fabs(point[axis] - query[axis]))
        search_tree(ctx, far, next_axis, query, best, best_point);
}

int64_t k_d_tree(const double *input, size_t length, double *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || length > 51) return INVALID_RESULT;
    const double dimension_value = input[0];
    if (!isfinite(dimension_value) || floor(dimension_value) != dimension_value ||
        (dimension_value != 2.0 && dimension_value != 3.0)) return INVALID_RESULT;
    const size_t dimension = (size_t)dimension_value;
    const double count_value = input[1];
    if (!isfinite(count_value) || floor(count_value) != count_value ||
        count_value < 1.0 || count_value > MAX_POINTS) return INVALID_RESULT;
    const size_t count = (size_t)count_value;
    if (length != 2 + dimension * (count + 1)) return INVALID_RESULT;
    double query[MAX_DIMENSION] = {0.0, 0.0, 0.0};
    for (size_t a = 0; a < dimension; ++a) {
        const double value = input[2 + a];
        if (!isfinite(value) || floor(value) != value || value < -1000.0 || value > 1000.0)
            return INVALID_RESULT;
        query[a] = value;
    }
    double points[MAX_POINTS][MAX_DIMENSION] = {{0.0}};
    const size_t offset = 2 + dimension;
    for (size_t i = 0; i < count; ++i) {
        for (size_t a = 0; a < dimension; ++a) {
            const double value = input[offset + i * dimension + a];
            if (!isfinite(value) || floor(value) != value || value < -1000.0 || value > 1000.0)
                return INVALID_RESULT;
            points[i][a] = value;
        }
    }
    for (size_t a = 0; a < dimension; ++a)
        for (size_t i = 0; i < count; ++i)
            for (size_t j = i + 1; j < count; ++j)
                if (points[i][a] == points[j][a]) return INVALID_RESULT;

    double smallest_squared = INFINITY;
    size_t nearest_count = 0;
    for (size_t i = 0; i < count; ++i) {
        double squared = 0.0;
        for (size_t a = 0; a < dimension; ++a) {
            const double delta = query[a] - points[i][a];
            squared += delta * delta;
        }
        if (squared < smallest_squared) { smallest_squared = squared; nearest_count = 1; }
        else if (squared == smallest_squared) ++nearest_count;
    }
    if (nearest_count != 1) return INVALID_RESULT;
    const size_t output_length = dimension + 1;
    if (output == NULL || output_capacity < output_length) return OUTPUT_ERROR;

    build_context ctx = {.points = points, .dimension = dimension, .used = 0};
    for (size_t i = 0; i < count; ++i) ctx.ids[i] = i;
    const size_t root = build_tree(&ctx, 0, count - 1, 0);
    double best = INFINITY;
    size_t best_point = SIZE_MAX;
    search_tree(&ctx, root, 0, query, &best, &best_point);
    output[0] = best;
    for (size_t a = 0; a < dimension; ++a) output[a + 1] = points[best_point][a];
    return (int64_t)output_length;
}
