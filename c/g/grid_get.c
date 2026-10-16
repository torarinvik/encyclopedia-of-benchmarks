#include <stddef.h>
#include <stdint.h>
#define MAX_COLUMNS INT64_C(1000)
#define MAX_INDEX INT64_C(10000)
int64_t grid_get(const int64_t *values, size_t length) {
    if (values == NULL || length < 3 || length > 4) return -1;
    const int64_t op=values[0], columns=values[1], index=values[2];
    if ((op!=0 && op!=1) || columns<1 || columns>MAX_COLUMNS || index<0 || index>MAX_INDEX) return -1;
    if (op == 0) {
        int64_t remaining = index;
        while (remaining + 1 > columns) remaining -= columns;
        return remaining + 1;
    }
    return index / columns + 1;
}
