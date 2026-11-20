#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define CC_MAX_V 24
#define CC_MAX_F 8
#define CC_MAX_D 8
#define CC_MAX_E 32
#define CC_MAX_IN 122
#define CC_MAX_OUT 386

static int cc_integer(double value, int low, int high, int *result) {
    if (!isfinite(value) || trunc(value) != value || value < (double)low || value > (double)high) return 0;
    *result = (int)value;
    return 1;
}

static double cc_mean(const double *values, int count) {
    double scale = 0.0;
    for (int i = 0; i < count; ++i) if (fabs(values[i]) > scale) scale = fabs(values[i]);
    if (scale == 0.0) return 0.0;
    double sum = 0.0;
    for (int i = 0; i < count; ++i) sum += values[i] / scale;
    return (sum / (double)count) * scale;
}

static double cc_average4(double a, double b, double c, double d) {
    double scale = fmax(fmax(fabs(a), fabs(b)), fmax(fabs(c), fabs(d)));
    if (scale == 0.0) return 0.0;
    return ((a / scale + b / scale + c / scale + d / scale) * 0.25) * scale;
}

static int cc_same_edge(int a, int b, int u, int v) {
    return a == u && b == v;
}

int64_t catmull_clark_subdivision(const double *input, size_t length,
                                 double *output, size_t capacity) {
    if (input == NULL || length < 2 || length > CC_MAX_IN) return -1;
    for (size_t i = 0; i < length; ++i) if (!isfinite(input[i])) return -1;
    int vertex_count, face_count;
    if (!cc_integer(input[0], 0, CC_MAX_V, &vertex_count) ||
        !cc_integer(input[1], 0, CC_MAX_F, &face_count)) return -1;
    if ((vertex_count == 0 || face_count == 0) &&
        !(vertex_count == 0 && face_count == 0 && length == 2)) return -1;

    double x[CC_MAX_V] = {0}, y[CC_MAX_V] = {0};
    int degree[CC_MAX_F] = {0};
    int face[CC_MAX_F][CC_MAX_D] = {{0}};
    size_t position = 2;
    if (position + (size_t)(2 * vertex_count) > length) return -1;
    for (int v = 0; v < vertex_count; ++v) {
        x[v] = input[position++];
        y[v] = input[position++];
    }

    int edge_u[CC_MAX_E], edge_v[CC_MAX_E], edge_f0[CC_MAX_E], edge_f1[CC_MAX_E];
    int edge_uses[CC_MAX_E] = {0};
    int edge_count = 0;
    for (int f = 0; f < face_count; ++f) {
        if (position >= length || !cc_integer(input[position++], 3, CC_MAX_D, &degree[f])) return -1;
        if (position + (size_t)degree[f] > length) return -1;
        for (int i = 0; i < degree[f]; ++i) {
            if (!cc_integer(input[position++], 0, vertex_count - 1, &face[f][i])) return -1;
            for (int j = 0; j < i; ++j) if (face[f][i] == face[f][j]) return -1;
        }
        for (int i = 0; i < degree[f]; ++i) {
            int a = face[f][i], b = face[f][(i + 1) % degree[f]];
            int u = a < b ? a : b, v = a < b ? b : a, found = -1;
            for (int e = 0; e < edge_count; ++e)
                if (cc_same_edge(edge_u[e], edge_v[e], u, v)) { found = e; break; }
            if (found < 0) {
                if (edge_count == CC_MAX_E) return -1;
                found = edge_count++;
                edge_u[found] = u; edge_v[found] = v;
                edge_f0[found] = f; edge_f1[found] = -1;
                edge_uses[found] = 1;
            } else {
                if (edge_uses[found] != 1 || edge_f0[found] == f) return -1;
                edge_uses[found] = 2;
                edge_f1[found] = f;
            }
        }
    }
    if (position != length) return -1;
    for (int e = 0; e < edge_count; ++e) if (edge_uses[e] != 2) return -1;

    for (int v = 0; v < vertex_count; ++v) {
        int link_a[CC_MAX_F], link_b[CC_MAX_F], links = 0, valence = 0;
        for (int e = 0; e < edge_count; ++e) if (edge_u[e] == v || edge_v[e] == v) ++valence;
        for (int f = 0; f < face_count; ++f) {
            for (int i = 0; i < degree[f]; ++i) if (face[f][i] == v) {
                int a = face[f][(i + degree[f] - 1) % degree[f]];
                int b = face[f][(i + 1) % degree[f]];
                int lo = a < b ? a : b, hi = a < b ? b : a;
                for (int j = 0; j < links; ++j) {
                    int old_lo = link_a[j] < link_b[j] ? link_a[j] : link_b[j];
                    int old_hi = link_a[j] < link_b[j] ? link_b[j] : link_a[j];
                    if (lo == old_lo && hi == old_hi) return -1;
                }
                link_a[links] = a; link_b[links++] = b;
            }
        }
        if (valence < 3 || links != valence) return -1;
        int reached[CC_MAX_V] = {0}, changed = 1;
        reached[link_a[0]] = 1;
        while (changed) {
            changed = 0;
            for (int i = 0; i < links; ++i) {
                if (reached[link_a[i]] && !reached[link_b[i]]) { reached[link_b[i]] = 1; changed = 1; }
                if (reached[link_b[i]] && !reached[link_a[i]]) { reached[link_a[i]] = 1; changed = 1; }
            }
        }
        int node_degree[CC_MAX_V] = {0}, node_count = 0;
        for (int i = 0; i < links; ++i) { ++node_degree[link_a[i]]; ++node_degree[link_b[i]]; }
        for (int node = 0; node < vertex_count; ++node) if (node_degree[node] != 0) {
            ++node_count;
            if (node_degree[node] != 2 || !reached[node]) return -1;
        }
        if (node_count < 3) return -1;
    }

    for (int i = 1; i < edge_count; ++i) {
        int u = edge_u[i], v = edge_v[i], f0 = edge_f0[i], f1 = edge_f1[i], j = i;
        while (j > 0 && (edge_u[j - 1] > u || (edge_u[j - 1] == u && edge_v[j - 1] > v))) {
            edge_u[j] = edge_u[j - 1]; edge_v[j] = edge_v[j - 1];
            edge_f0[j] = edge_f0[j - 1]; edge_f1[j] = edge_f1[j - 1]; --j;
        }
        edge_u[j] = u; edge_v[j] = v; edge_f0[j] = f0; edge_f1[j] = f1;
    }

    double face_x[CC_MAX_F] = {0}, face_y[CC_MAX_F] = {0};
    for (int f = 0; f < face_count; ++f) {
        double values_x[CC_MAX_D], values_y[CC_MAX_D];
        for (int i = 0; i < degree[f]; ++i) { values_x[i] = x[face[f][i]]; values_y[i] = y[face[f][i]]; }
        face_x[f] = cc_mean(values_x, degree[f]); face_y[f] = cc_mean(values_y, degree[f]);
    }

    double staged[CC_MAX_OUT];
    int output_vertices = vertex_count + edge_count + face_count;
    int output_faces = 0;
    for (int f = 0; f < face_count; ++f) output_faces += degree[f];
    size_t out = 0;
    staged[out++] = (double)output_vertices; staged[out++] = (double)output_faces;
    for (int v = 0; v < vertex_count; ++v) {
        double fx[CC_MAX_F], fy[CC_MAX_F], rx[CC_MAX_F], ry[CC_MAX_F];
        int nf = 0, ne = 0;
        for (int f = 0; f < face_count; ++f) {
            for (int i = 0; i < degree[f]; ++i) if (face[f][i] == v) {
                fx[nf] = face_x[f]; fy[nf++] = face_y[f]; break;
            }
        }
        for (int e = 0; e < edge_count; ++e) if (edge_u[e] == v || edge_v[e] == v) {
            rx[ne] = cc_mean((double[]){x[edge_u[e]], x[edge_v[e]]}, 2);
            ry[ne] = cc_mean((double[]){y[edge_u[e]], y[edge_v[e]]}, 2);
            ++ne;
        }
        double face_avg_x = cc_mean(fx, nf), face_avg_y = cc_mean(fy, nf);
        double edge_avg_x = cc_mean(rx, ne), edge_avg_y = cc_mean(ry, ne);
        double scale_x = fmax(fabs(x[v]), fmax(fabs(face_avg_x), fabs(edge_avg_x)));
        double scale_y = fmax(fabs(y[v]), fmax(fabs(face_avg_y), fabs(edge_avg_y)));
        double next_x = scale_x == 0.0 ? 0.0 :
            ((face_avg_x / scale_x + 2.0 * edge_avg_x / scale_x + (ne - 3) * (x[v] / scale_x)) / ne) * scale_x;
        double next_y = scale_y == 0.0 ? 0.0 :
            ((face_avg_y / scale_y + 2.0 * edge_avg_y / scale_y + (ne - 3) * (y[v] / scale_y)) / ne) * scale_y;
        staged[out++] = next_x; staged[out++] = next_y;
    }
    for (int e = 0; e < edge_count; ++e) {
        staged[out++] = cc_average4(x[edge_u[e]], x[edge_v[e]], face_x[edge_f0[e]], face_x[edge_f1[e]]);
        staged[out++] = cc_average4(y[edge_u[e]], y[edge_v[e]], face_y[edge_f0[e]], face_y[edge_f1[e]]);
    }
    for (int f = 0; f < face_count; ++f) { staged[out++] = face_x[f]; staged[out++] = face_y[f]; }
    for (int f = 0; f < face_count; ++f) for (int i = 0; i < degree[f]; ++i) {
        int v = face[f][i], next = face[f][(i + 1) % degree[f]], prev = face[f][(i + degree[f] - 1) % degree[f]];
        int a = v < next ? v : next, b = v < next ? next : v, next_edge = 0;
        int c = prev < v ? prev : v, d = prev < v ? v : prev, prev_edge = 0;
        for (int e = 0; e < edge_count; ++e) {
            if (edge_u[e] == a && edge_v[e] == b) next_edge = e;
            if (edge_u[e] == c && edge_v[e] == d) prev_edge = e;
        }
        staged[out++] = (double)v;
        staged[out++] = (double)(vertex_count + next_edge);
        staged[out++] = (double)(vertex_count + edge_count + f);
        staged[out++] = (double)(vertex_count + prev_edge);
    }
    if (out > CC_MAX_OUT) return -1;
    if (output == NULL || capacity < out) return -2;
    for (size_t i = 0; i < out; ++i) output[i] = staged[i];
    return (int64_t)out;
}
