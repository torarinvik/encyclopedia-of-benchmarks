/* Uncompiled draft: independently written from the matrix-tree identity. */
#include <stddef.h>
#include <stdint.h>

static int64_t determinant(int64_t matrix[6][6], int n) {
    if (n == 0) return 1;
    int64_t previous = 1;
    for (int k = 0; k < n - 1; ++k) {
        int64_t pivot = matrix[k][k];
        if (pivot == 0) return 0;
        for (int i = k + 1; i < n; ++i)
            for (int j = k + 1; j < n; ++j)
                matrix[i][j] = (matrix[i][j] * pivot - matrix[i][k] * matrix[k][j]) / previous;
        for (int i = k + 1; i < n; ++i) matrix[i][k] = 0;
        previous = pivot;
    }
    return matrix[n-1][n-1];
}

static int64_t minor_det(const int64_t laplacian[6][6], int n, int first, int second) {
    int64_t matrix[6][6] = {{0}};
    int row = 0;
    for (int i = 0; i < n; ++i) if (i != first && i != second) {
        int column = 0;
        for (int j = 0; j < n; ++j) if (j != first && j != second)
            matrix[row][column++] = laplacian[i][j];
        ++row;
    }
    return determinant(matrix, row);
}

int64_t effective_resistance_unit_graph(const int64_t *input, size_t length) {
    if (!input || length < 4 || length > 35) return -1;
    int64_t n64 = input[0], m64 = input[1], s64 = input[2], t64 = input[3];
    if (n64 < 2 || n64 > 6 || m64 < 0 || m64 > 15 || s64 < 0 || s64 >= n64 ||
        t64 < 0 || t64 >= n64 || s64 == t64 || length != (size_t)(4 + 2*m64)) return -1;
    int n = (int)n64, m = (int)m64, s = (int)s64, t = (int)t64;
    int seen[6][6] = {{0}};
    int64_t laplacian[6][6] = {{0}};
    for (int i = 0; i < m; ++i) {
        int64_t u64 = input[4+2*i], v64 = input[5+2*i];
        if (u64 < 0 || u64 >= n || v64 < 0 || v64 >= n || u64 == v64) return -1;
        int u = (int)u64, v = (int)v64;
        if (seen[u][v]) return -1;
        seen[u][v] = seen[v][u] = 1;
        ++laplacian[u][u]; ++laplacian[v][v];
        --laplacian[u][v]; --laplacian[v][u];
    }
    int64_t trees = minor_det(laplacian, n, t, -1);
    if (trees <= 0) return -1;
    int64_t forests = minor_det(laplacian, n, s, t);
    int64_t a = trees, b = forests;
    while (b) { int64_t remainder = a % b; a = b; b = remainder; }
    return (forests / a) * 65536 + trees / a;
}
