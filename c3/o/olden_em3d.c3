module olden_em3d;

const usz MAX_NODES = 8;
const usz MAX_DEGREE = 4;
const usz MAX_EDGES = MAX_NODES * MAX_DEGREE;

fn long olden_em3d(double* input, usz input_length, double* output, usz output_capacity)
    @export("olden_em3d") {
    if (input == null || input_length < 2) return -1;
    double requested_n = input[0];
    double requested_degree = input[1];
    if (requested_n != requested_n || requested_degree != requested_degree ||
        requested_n < 1.0 || requested_n > (double)MAX_NODES ||
        requested_n != (double)(usz)requested_n || requested_degree < 1.0 ||
        requested_degree > (double)MAX_DEGREE || requested_degree != (double)(usz)requested_degree) return -1;
    usz n = (usz)requested_n;
    usz degree = (usz)requested_degree;
    usz edges = n * degree;
    if (input_length != 2 + 2 * n + 4 * edges) return -1;
    double[MAX_NODES] electric;
    double[MAX_NODES] magnetic;
    usz offset = 2;
    for (usz i = 0; i < n; i++) {
        if (!(input[offset + i] >= 0.0 && input[offset + i] <= 1.0)) return -1;
        electric[i] = input[offset + i];
    }
    offset += n;
    for (usz i = 0; i < n; i++) {
        if (!(input[offset + i] >= 0.0 && input[offset + i] <= 1.0)) return -1;
        magnetic[i] = input[offset + i];
    }
    offset += n;
    usz e_neighbors = offset; offset += edges;
    usz e_coefficients = offset; offset += edges;
    usz h_neighbors = offset; offset += edges;
    usz h_coefficients = offset;
    for (usz i = 0; i < edges; i++) {
        if (!(input[e_neighbors + i] >= 0.0 && input[e_neighbors + i] < (double)n) ||
            input[e_neighbors + i] != (double)(usz)input[e_neighbors + i] ||
            !(input[h_neighbors + i] >= 0.0 && input[h_neighbors + i] < (double)n) ||
            input[h_neighbors + i] != (double)(usz)input[h_neighbors + i] ||
            !(input[e_coefficients + i] >= 0.0 && input[e_coefficients + i] <= 1.0) ||
            !(input[h_coefficients + i] >= 0.0 && input[h_coefficients + i] <= 1.0)) return -1;
        usz start = (i / degree) * degree;
        for (usz j = start; j < i; j++)
            if (input[e_neighbors + j] == input[e_neighbors + i] || input[h_neighbors + j] == input[h_neighbors + i]) return -1;
    }
    if (output == null || output_capacity < 2 * n) return -2;
    for (usz node = 0; node < n; node++) {
        double current = electric[node];
        usz base = node * degree;
        for (usz edge = 0; edge < degree; edge++) {
            usz coefficient = base + (edge & ~(usz)1);
            current -= input[e_coefficients + coefficient] * magnetic[(usz)input[e_neighbors + base + edge]];
        }
        electric[node] = current;
    }
    for (usz node = 0; node < n; node++) {
        double current = magnetic[node];
        usz base = node * degree;
        for (usz edge = 0; edge < degree; edge++) {
            usz coefficient = base + (edge & ~(usz)1);
            current -= input[h_coefficients + coefficient] * electric[(usz)input[h_neighbors + base + edge]];
        }
        magnetic[node] = current;
    }
    for (usz i = 0; i < n; i++) { output[i] = electric[i]; output[n + i] = magnetic[i]; }
    return (long)(2 * n);
}
