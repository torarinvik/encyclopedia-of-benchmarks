#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_NODES = 8, MAX_DEGREE = 4, MAX_EDGES = MAX_NODES * MAX_DEGREE };

int64_t olden_em3d(const double *input, size_t input_length,
                   double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 2) return -1;
    double requested_n = input[0], requested_degree = input[1];
    if (!(requested_n >= 1.0 && requested_n <= MAX_NODES) ||
        requested_n != (double)(int)requested_n ||
        !(requested_degree >= 1.0 && requested_degree <= MAX_DEGREE) ||
        requested_degree != (double)(int)requested_degree) return -1;
    size_t n = (size_t)requested_n, degree = (size_t)requested_degree;
    size_t edges = n * degree;
    if (input_length != 2 + 2 * n + 4 * edges) return -1;
    double electric[MAX_NODES], magnetic[MAX_NODES];
    size_t offset = 2;
    for (size_t i = 0; i < n; ++i) {
        if (!(input[offset + i] >= 0.0 && input[offset + i] <= 1.0)) return -1;
        electric[i] = input[offset + i];
    }
    offset += n;
    for (size_t i = 0; i < n; ++i) {
        if (!(input[offset + i] >= 0.0 && input[offset + i] <= 1.0)) return -1;
        magnetic[i] = input[offset + i];
    }
    offset += n;
    const double *e_neighbors = input + offset; offset += edges;
    const double *e_coefficients = input + offset; offset += edges;
    const double *h_neighbors = input + offset; offset += edges;
    const double *h_coefficients = input + offset;
    for (size_t i = 0; i < edges; ++i) {
        if (!(e_neighbors[i] >= 0.0 && e_neighbors[i] < (double)n) ||
            e_neighbors[i] != (double)(int)e_neighbors[i] ||
            !(h_neighbors[i] >= 0.0 && h_neighbors[i] < (double)n) ||
            h_neighbors[i] != (double)(int)h_neighbors[i] ||
            !(e_coefficients[i] >= 0.0 && e_coefficients[i] <= 1.0) ||
            !(h_coefficients[i] >= 0.0 && h_coefficients[i] <= 1.0)) return -1;
        for (size_t j = (i / degree) * degree; j < i; ++j)
            if (e_neighbors[j] == e_neighbors[i] || h_neighbors[j] == h_neighbors[i]) return -1;
    }
    if (output == NULL || output_capacity < 2 * n) return -2;
    for (size_t node = 0; node < n; ++node) {
        double current = electric[node];
        size_t base = node * degree;
        for (size_t edge = 0; edge < degree; ++edge) {
            size_t coefficient = base + (edge & ~(size_t)1);
            current -= e_coefficients[coefficient] * magnetic[(size_t)e_neighbors[base + edge]];
        }
        electric[node] = current;
    }
    for (size_t node = 0; node < n; ++node) {
        double current = magnetic[node];
        size_t base = node * degree;
        for (size_t edge = 0; edge < degree; ++edge) {
            size_t coefficient = base + (edge & ~(size_t)1);
            current -= h_coefficients[coefficient] * electric[(size_t)h_neighbors[base + edge]];
        }
        magnetic[node] = current;
    }
    for (size_t i = 0; i < n; ++i) output[i] = electric[i];
    for (size_t i = 0; i < n; ++i) output[n + i] = magnetic[i];
    return (int64_t)(2 * n);
}
