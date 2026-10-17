#include <stddef.h>
#include <stdint.h>

static void store_i32_le(uint32_t value, uint8_t *out, size_t offset) {
    for (size_t b = 0; b < 4; ++b) out[offset + b] = (uint8_t)(value >> (8 * b));
}

int64_t subtract(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4) return -2;
    if (input[0] < 0 || input[0] > 16 || input[1] < 0 || input[1] > 16) return -2;
    size_t rows_a=(size_t)input[0], cols_a=(size_t)input[1];
    if (rows_a==0 && cols_a!=0) return -2;
    size_t cells_a=rows_a*cols_a, bdim=2+cells_a;
    if (bdim+2>length || input[bdim]<0 || input[bdim]>16 || input[bdim+1]<0 || input[bdim+1]>16) return -2;
    size_t rows_b=(size_t)input[bdim], cols_b=(size_t)input[bdim+1];
    if (rows_b==0 && cols_b!=0) return -2;
    size_t cells_b=rows_b*cols_b;
    if (length!=bdim+2+cells_b) return -2;
    if (rows_a!=rows_b || cols_a!=cols_b) return -1;
    for(size_t i=0;i<cells_a;i++) if(input[2+i]<INT32_MIN||input[2+i]>INT32_MAX||input[bdim+2+i]<INT32_MIN||input[bdim+2+i]>INT32_MAX)return -2;
    if (capacity < cells_a*4 || (cells_a!=0 && output==NULL)) return -3;
    for(size_t i=0;i<cells_a;i++) store_i32_le((uint32_t)(int32_t)input[2+i]-(uint32_t)(int32_t)input[bdim+2+i],output,i*4);
    return (int64_t)cells_a;
}
