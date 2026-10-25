#include <cstddef>
#include <cstdint>

namespace { constexpr size_t max_nodes = 8; constexpr size_t max_degree = 4; }

extern "C" int64_t olden_em3d(const double *input, size_t input_length,
                              double *output, size_t output_capacity)
{
    if (input == nullptr || input_length < 2) return -1;
    const double rn = input[0], rd = input[1];
    if (!(rn >= 1.0 && rn <= static_cast<double>(max_nodes)) || rn != static_cast<double>(static_cast<size_t>(rn)) ||
        !(rd >= 1.0 && rd <= static_cast<double>(max_degree)) || rd != static_cast<double>(static_cast<size_t>(rd))) return -1;
    const size_t n = static_cast<size_t>(rn), degree = static_cast<size_t>(rd), edges = n * degree;
    if (input_length != 2 + 2 * n + 4 * edges) return -1;
    double electric[max_nodes], magnetic[max_nodes];
    size_t offset = 2;
    for (size_t i = 0; i < n; ++i) { if (!(input[offset+i] >= 0.0 && input[offset+i] <= 1.0)) return -1; electric[i] = input[offset+i]; }
    offset += n;
    for (size_t i = 0; i < n; ++i) { if (!(input[offset+i] >= 0.0 && input[offset+i] <= 1.0)) return -1; magnetic[i] = input[offset+i]; }
    offset += n;
    const size_t e_neighbors = offset; offset += edges;
    const size_t e_coefficients = offset; offset += edges;
    const size_t h_neighbors = offset; offset += edges;
    const size_t h_coefficients = offset;
    for (size_t i = 0; i < edges; ++i) {
        const double en = input[e_neighbors+i], hn = input[h_neighbors+i];
        if (!(en >= 0.0 && en < static_cast<double>(n)) || en != static_cast<double>(static_cast<size_t>(en)) ||
            !(hn >= 0.0 && hn < static_cast<double>(n)) || hn != static_cast<double>(static_cast<size_t>(hn)) ||
            !(input[e_coefficients+i] >= 0.0 && input[e_coefficients+i] <= 1.0) ||
            !(input[h_coefficients+i] >= 0.0 && input[h_coefficients+i] <= 1.0)) return -1;
        const size_t start = (i / degree) * degree;
        for (size_t j = start; j < i; ++j)
            if (input[e_neighbors+j] == en || input[h_neighbors+j] == hn) return -1;
    }
    if (output == nullptr || output_capacity < 2*n) return -2;
    for (size_t node = 0; node < n; ++node) {
        double current = electric[node]; const size_t base = node * degree;
        for (size_t edge = 0; edge < degree; ++edge) {
            const size_t coefficient = base + (edge & ~size_t(1));
            current -= input[e_coefficients+coefficient] * magnetic[static_cast<size_t>(input[e_neighbors+base+edge])];
        }
        electric[node] = current;
    }
    for (size_t node = 0; node < n; ++node) {
        double current = magnetic[node]; const size_t base = node * degree;
        for (size_t edge = 0; edge < degree; ++edge) {
            const size_t coefficient = base + (edge & ~size_t(1));
            current -= input[h_coefficients+coefficient] * electric[static_cast<size_t>(input[h_neighbors+base+edge])];
        }
        magnetic[node] = current;
    }
    for (size_t i = 0; i < n; ++i) { output[i] = electric[i]; output[n+i] = magnetic[i]; }
    return static_cast<int64_t>(2*n);
}
