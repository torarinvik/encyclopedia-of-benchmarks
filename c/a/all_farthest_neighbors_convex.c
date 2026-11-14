#include <stddef.h>
#include <stdint.h>

typedef struct { int64_t x, y; } Point;
static int64_t value(const Point *points, int n, int row, int col) {
    if (col <= row) return col-row;
    if (col >= row+n) return -1;
    Point a = points[row], b = points[col%n];
    int64_t dx = a.x-b.x, dy = a.y-b.y;
    return dx*dx+dy*dy;
}

/* Column reduction followed by odd-row recursion and bounded interpolation. */
static void maxima(const Point *points, int n, const int *rows, int nr,
                   const int *columns, int nc, int *answer) {
    if (!nr) return;
    int reduced[127], count = 0;
    for (int c = 0; c < nc; ++c) {
        int candidate = columns[c];
        while (count > 0 && value(points,n,rows[count-1],candidate) >
                            value(points,n,rows[count-1],reduced[count-1])) --count;
        if (count < nr) reduced[count++] = candidate;
    }
    int odd[32], odd_count = 0;
    for (int i = 1; i < nr; i += 2) odd[odd_count++] = rows[i];
    maxima(points,n,odd,odd_count,reduced,count,answer);
    int low = 0;
    for (int i = 0; i < nr; i += 2) {
        int high = count-1;
        if (i+1 < nr) {
            high = low;
            while (reduced[high] != answer[rows[i+1]]) ++high;
        }
        int best = low;
        for (int j = low+1; j <= high; ++j)
            if (value(points,n,rows[i],reduced[j]) > value(points,n,rows[i],reduced[best])) best = j;
        answer[rows[i]] = reduced[best];
        low = high;
    }
}

int64_t all_farthest_neighbors_convex(const int64_t *input, size_t length,
                                      uint8_t *output, size_t capacity) {
    if (!input || length < 7 || length > 129 || input[0] < 3 || input[0] > 64) return -1;
    int n = (int)input[0];
    if (length != 1+2*(size_t)n) return -1;
    Point points[64];
    for (int i = 0; i < n; ++i) {
        int64_t x = input[1+2*i], y = input[2+2*i];
        if (x < -1000000 || x > 1000000 || y < -1000000 || y > 1000000) return -1;
        points[i] = (Point){x,y};
    }
    for (int i = 0; i < n; ++i) {
        Point a=points[i], b=points[(i+1)%n], c=points[(i+2)%n];
        if ((b.x-a.x)*(c.y-b.y)-(b.y-a.y)*(c.x-b.x) >= 0) return -1;
    }
    if (!output || capacity < 8*(size_t)n) return -2;
    int rows[64], cols[127], answer[64] = {0};
    for (int i = 0; i < n; ++i) rows[i] = i;
    for (int i = 0; i < 2*n-1; ++i) cols[i] = i;
    maxima(points,n,rows,n,cols,2*n-1,answer);
    for (int i = 0; i < n; ++i) {
        uint64_t index = (uint64_t)(answer[i]%n);
        for (size_t b = 0; b < 8; ++b) output[8*(size_t)i+b] = (uint8_t)(index >> (8*b));
    }
    return 8*n;
}
