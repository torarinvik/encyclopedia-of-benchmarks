module olden_bh;

const int MIN_BODIES = 2;
const int MAX_BODIES = 16;
const int MAX_NODES = 1024;
const int MAX_DEPTH = 16;
extern fn double sqrt(double value);

struct Body { double[3] position; double mass; }
struct Cell { int body; int[8] child; double mass; double[3] center; }

fn int octant(double* position, double* center) {
    return (position[0] >= center[0] ? 1 : 0) | ((position[1] >= center[1] ? 1 : 0) << 1) |
           ((position[2] >= center[2] ? 1 : 0) << 2);
}

fn int new_cell(Cell* cells, int* used) {
    if (used[0] >= MAX_NODES) return -1;
    int index = used[0]; used[0] += 1;
    cells[index].body = -1; cells[index].mass = 0.0;
    for (int i = 0; i < 8; ++i) cells[index].child[i] = -1;
    for (int i = 0; i < 3; ++i) cells[index].center[i] = 0.0;
    return index;
}

fn void child_center(double* center, double half, int child, double* result) {
    for (int axis = 0; axis < 3; ++axis)
        result[axis] = center[axis] + ((child & (1 << axis)) != 0 ? half / 2.0 : -half / 2.0);
}

fn bool insert_body(Cell* cells, int* used, int cell_index, int body_index,
                    double* center, double half, int depth, Body* bodies) {
    int old_body = cells[cell_index].body;
    if (old_body == -1) { cells[cell_index].body = body_index; return true; }
    if (depth >= MAX_DEPTH) return false;
    if (old_body >= 0) cells[cell_index].body = -2;
    int[2] items = {old_body, body_index};
    int item_count = old_body >= 0 ? 2 : 1;
    for (int item = 0; item < item_count; ++item) {
        int which_body = old_body >= 0 ? items[item] : body_index;
        int child = octant(&bodies[which_body].position[0], center);
        if (cells[cell_index].child[child] < 0) {
            int created = new_cell(cells, used);
            if (created < 0) return false;
            cells[cell_index].child[child] = created;
        }
        double[3] next_center;
        child_center(center, half, child, &next_center[0]);
        if (!insert_body(cells, used, cells[cell_index].child[child], which_body,
                         &next_center[0], half / 2.0, depth + 1, bodies)) return false;
    }
    return true;
}

fn void aggregate(Cell* cells, int cell_index, Body* bodies) {
    Cell* cell = &cells[cell_index];
    if (cell.body >= 0) {
        cell.mass = bodies[cell.body].mass;
        for (int axis = 0; axis < 3; ++axis) cell.center[axis] = bodies[cell.body].position[axis];
        return;
    }
    double[3] weighted = {0.0, 0.0, 0.0};
    cell.mass = 0.0;
    for (int child = 0; child < 8; ++child) {
        int child_index = cell.child[child];
        if (child_index < 0) continue;
        aggregate(cells, child_index, bodies);
        cell.mass += cells[child_index].mass;
        for (int axis = 0; axis < 3; ++axis)
            weighted[axis] += cells[child_index].mass * cells[child_index].center[axis];
    }
    for (int axis = 0; axis < 3; ++axis) cell.center[axis] = weighted[axis] / cell.mass;
}

fn void interact(double mass, double* position, double* query, double eps_sq,
                 double* potential, double* acceleration) {
    double[3] d; double r2 = eps_sq;
    for (int axis = 0; axis < 3; ++axis) { d[axis] = position[axis] - query[axis]; r2 += d[axis] * d[axis]; }
    double contribution = mass / sqrt(r2);
    potential[0] -= contribution;
    double scale = contribution / r2;
    for (int axis = 0; axis < 3; ++axis) acceleration[axis] += d[axis] * scale;
}

fn void walk(Cell* cells, int cell_index, double side, double theta_sq, double* query,
             double eps_sq, double* potential, double* acceleration, Body* bodies) {
    Cell* cell = &cells[cell_index];
    if (cell.body >= 0) { interact(bodies[cell.body].mass, &bodies[cell.body].position[0], query, eps_sq, potential, acceleration); return; }
    double distance_sq = 0.0;
    for (int axis = 0; axis < 3; ++axis) { double d = cell.center[axis] - query[axis]; distance_sq += d * d; }
    if (theta_sq * distance_sq < side * side) {
        for (int child = 0; child < 8; ++child)
            if (cell.child[child] >= 0) walk(cells, cell.child[child], side / 2.0, theta_sq, query, eps_sq, potential, acceleration, bodies);
    } else interact(cell.mass, &cell.center[0], query, eps_sq, potential, acceleration);
}

fn long olden_bh(double* input, usz input_length, double* output, usz output_capacity) @export("olden_bh") {
    if (input == null || input_length < 6) return -1;
    double requested_count = input[0], theta = input[1], softening = input[2];
    if (!(requested_count >= MIN_BODIES && requested_count <= MAX_BODIES) || requested_count != (double)(int)requested_count ||
        !(theta >= 0.0 && theta <= 2.0) || !(softening >= 0.0 && softening <= 1.0)) return -1;
    int count = (int)requested_count;
    if (input_length != 6 + 4 * (usz)count) return -1;
    double[3] query = {input[3], input[4], input[5]};
    Body[MAX_BODIES] bodies = {};
    double[3] minima = {32.0, 32.0, 32.0}, maxima = {-32.0, -32.0, -32.0};
    for (int body = 0; body < count; ++body) {
        for (int axis = 0; axis < 3; ++axis) {
            double value = input[6 + 4 * body + axis];
            if (!(value >= -32.0 && value <= 32.0) || value != (double)(int)value || !(query[axis] >= -32.0 && query[axis] <= 32.0)) return -1;
            bodies[body].position[axis] = value;
            if (value < minima[axis]) minima[axis] = value;
            if (value > maxima[axis]) maxima[axis] = value;
        }
        double mass = input[9 + 4 * body];
        if (!(mass >= 1.0 && mass <= 16.0)) return -1;
        bodies[body].mass = mass;
    }
    for (int a = 0; a < count; ++a) for (int b = a + 1; b < count; ++b)
        if (bodies[a].position[0] == bodies[b].position[0] && bodies[a].position[1] == bodies[b].position[1] && bodies[a].position[2] == bodies[b].position[2]) return -1;
    bool inside = true;
    for (int axis = 0; axis < 3; ++axis) if (query[axis] < minima[axis] || query[axis] > maxima[axis]) inside = false;
    if (inside) return -1;
    if (output == null || output_capacity < 4) return -2;
    double side = maxima[0] - minima[0];
    if (maxima[1] - minima[1] > side) side = maxima[1] - minima[1];
    if (maxima[2] - minima[2] > side) side = maxima[2] - minima[2];
    if (side <= 0.0) return -1;
    double[3] center;
    for (int axis = 0; axis < 3; ++axis) center[axis] = (minima[axis] + maxima[axis]) / 2.0;
    Cell[MAX_NODES] cells = {};
    int used = 0, root = new_cell(&cells[0], &used);
    for (int body = 0; body < count; ++body)
        if (!insert_body(&cells[0], &used, root, body, &center[0], side / 2.0, 0, &bodies[0])) return -1;
    aggregate(&cells[0], root, &bodies[0]);
    double potential = 0.0; double[3] acceleration = {0.0, 0.0, 0.0};
    walk(&cells[0], root, side, theta * theta, &query[0], softening * softening, &potential, &acceleration[0], &bodies[0]);
    output[0] = potential; output[1] = acceleration[0]; output[2] = acceleration[1]; output[3] = acceleration[2];
    return 4;
}
