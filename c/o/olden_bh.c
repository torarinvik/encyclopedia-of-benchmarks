#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum { MIN_BODIES = 2, MAX_BODIES = 16, MAX_NODES = 1024, MAX_DEPTH = 16 };

typedef struct { double position[3]; double mass; } Body;
typedef struct { int body; int child[8]; double mass; double center[3]; } Cell;

static int octant(const double position[3], const double center[3])
{
    return (position[0] >= center[0]) | ((position[1] >= center[1]) << 1) |
           ((position[2] >= center[2]) << 2);
}

static int new_cell(Cell cells[MAX_NODES], int *used)
{
    if (*used >= MAX_NODES) return -1;
    int index = (*used)++;
    cells[index].body = -1;
    cells[index].mass = 0.0;
    for (int child = 0; child < 8; ++child) cells[index].child[child] = -1;
    for (int axis = 0; axis < 3; ++axis) cells[index].center[axis] = 0.0;
    return index;
}

static void child_center(const double center[3], double half, int child, double result[3])
{
    for (int axis = 0; axis < 3; ++axis)
        result[axis] = center[axis] + ((child & (1 << axis)) ? half / 2.0 : -half / 2.0);
}

static int insert_body(Cell cells[MAX_NODES], int *used, int cell_index, int body_index,
                       const double center[3], double half, int depth,
                       const Body bodies[MAX_BODIES])
{
    int old_body = cells[cell_index].body;
    if (old_body == -1) {
        cells[cell_index].body = body_index;
        return 1;
    }
    if (depth >= MAX_DEPTH) return 0;
    if (old_body >= 0) cells[cell_index].body = -2;
    int items[2] = {old_body, body_index};
    int item_count = old_body >= 0 ? 2 : 1;
    for (int item = 0; item < item_count; ++item) {
        int which_body = old_body >= 0 ? items[item] : body_index;
        int child = octant(bodies[which_body].position, center);
        if (cells[cell_index].child[child] < 0) {
            int created = new_cell(cells, used);
            if (created < 0) return 0;
            cells[cell_index].child[child] = created;
        }
        double next_center[3];
        child_center(center, half, child, next_center);
        if (!insert_body(cells, used, cells[cell_index].child[child], which_body,
                         next_center, half / 2.0, depth + 1, bodies)) return 0;
    }
    return 1;
}

static void aggregate(Cell cells[MAX_NODES], int cell_index, const Body bodies[MAX_BODIES])
{
    Cell *cell = &cells[cell_index];
    if (cell->body >= 0) {
        cell->mass = bodies[cell->body].mass;
        for (int axis = 0; axis < 3; ++axis) cell->center[axis] = bodies[cell->body].position[axis];
        return;
    }
    double weighted[3] = {0.0, 0.0, 0.0};
    cell->mass = 0.0;
    for (int child = 0; child < 8; ++child) {
        int child_index = cell->child[child];
        if (child_index < 0) continue;
        aggregate(cells, child_index, bodies);
        cell->mass += cells[child_index].mass;
        for (int axis = 0; axis < 3; ++axis)
            weighted[axis] += cells[child_index].mass * cells[child_index].center[axis];
    }
    for (int axis = 0; axis < 3; ++axis) cell->center[axis] = weighted[axis] / cell->mass;
}

static void interact(double mass, const double position[3], const double query[3], double eps_sq,
                     double *potential, double acceleration[3])
{
    double displacement[3];
    double distance_sq = eps_sq;
    for (int axis = 0; axis < 3; ++axis) {
        displacement[axis] = position[axis] - query[axis];
        distance_sq += displacement[axis] * displacement[axis];
    }
    double distance = sqrt(distance_sq);
    double contribution = mass / distance;
    *potential -= contribution;
    double scale = contribution / distance_sq;
    for (int axis = 0; axis < 3; ++axis) acceleration[axis] += displacement[axis] * scale;
}

static void walk(const Cell cells[MAX_NODES], int cell_index, double side, double theta_sq,
                 const double query[3], double eps_sq, double *potential, double acceleration[3],
                 const Body bodies[MAX_BODIES])
{
    const Cell *cell = &cells[cell_index];
    if (cell->body >= 0) {
        interact(bodies[cell->body].mass, bodies[cell->body].position, query, eps_sq,
                 potential, acceleration);
        return;
    }
    double distance_sq = 0.0;
    for (int axis = 0; axis < 3; ++axis) {
        double displacement = cell->center[axis] - query[axis];
        distance_sq += displacement * displacement;
    }
    if (theta_sq * distance_sq < side * side) {
        for (int child = 0; child < 8; ++child)
            if (cell->child[child] >= 0)
                walk(cells, cell->child[child], side / 2.0, theta_sq, query, eps_sq,
                     potential, acceleration, bodies);
    } else {
        interact(cell->mass, cell->center, query, eps_sq, potential, acceleration);
    }
}

int64_t olden_bh(const double *input, size_t input_length, double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 6) return -1;
    double requested_count = input[0];
    double theta = input[1];
    double softening = input[2];
    if (!(requested_count >= MIN_BODIES && requested_count <= MAX_BODIES) ||
        requested_count != (double)(int)requested_count || !(theta >= 0.0 && theta <= 2.0) ||
        !(softening >= 0.0 && softening <= 1.0)) return -1;
    int count = (int)requested_count;
    if (input_length != 6U + 4U * (size_t)count) return -1;
    double query[3] = {input[3], input[4], input[5]};
    Body bodies[MAX_BODIES];
    double minima[3] = {32.0, 32.0, 32.0};
    double maxima[3] = {-32.0, -32.0, -32.0};
    for (int body = 0; body < count; ++body) {
        for (int axis = 0; axis < 3; ++axis) {
            double value = input[6 + 4 * body + axis];
            if (!(value >= -32.0 && value <= 32.0) || value != (double)(int)value ||
                !(query[axis] >= -32.0 && query[axis] <= 32.0)) return -1;
            bodies[body].position[axis] = value;
            if (value < minima[axis]) minima[axis] = value;
            if (value > maxima[axis]) maxima[axis] = value;
        }
        double mass = input[9 + 4 * body];
        if (!(mass >= 1.0 && mass <= 16.0)) return -1;
        bodies[body].mass = mass;
    }
    for (int a = 0; a < count; ++a)
        for (int b = a + 1; b < count; ++b)
            if (bodies[a].position[0] == bodies[b].position[0] &&
                bodies[a].position[1] == bodies[b].position[1] &&
                bodies[a].position[2] == bodies[b].position[2]) return -1;
    int inside = 1;
    for (int axis = 0; axis < 3; ++axis) {
        if (!(query[axis] >= minima[axis] && query[axis] <= maxima[axis])) inside = 0;
    }
    if (inside) return -1;
    if (output == NULL || output_capacity < 4) return -2;

    double side = fmax(maxima[0] - minima[0], fmax(maxima[1] - minima[1], maxima[2] - minima[2]));
    double center[3];
    for (int axis = 0; axis < 3; ++axis) center[axis] = (minima[axis] + maxima[axis]) / 2.0;
    Cell cells[MAX_NODES];
    int used = 0;
    int root = new_cell(cells, &used);
    if (root < 0 || side <= 0.0) return -1;
    for (int body = 0; body < count; ++body)
        if (!insert_body(cells, &used, root, body, center, side / 2.0, 0, bodies)) return -1;
    aggregate(cells, root, bodies);
    double potential = 0.0;
    double acceleration[3] = {0.0, 0.0, 0.0};
    walk(cells, root, side, theta * theta, query, softening * softening,
         &potential, acceleration, bodies);
    output[0] = potential;
    output[1] = acceleration[0];
    output[2] = acceleration[1];
    output[3] = acceleration[2];
    return 4;
}
