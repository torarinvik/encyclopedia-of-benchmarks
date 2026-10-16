#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT 32
#define MAX_CELLS ((MAX_TEXT + 1) * (MAX_TEXT + 1))
#define MAX_OUTPUT 34880

static void put_i64(uint8_t *out, size_t *pos, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[(*pos)++] = (uint8_t)(bits >> (8 * b));
}

extern "C" int64_t min_cost_string_conversion(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if (input == NULL || length < 6 || length > 70) return -1;
    int64_t src_n64 = input[0];
    if (src_n64 < 0 || src_n64 > MAX_TEXT) return -1;
    size_t src_n = (size_t)src_n64, dst_len_pos = 1 + src_n;
    if (dst_len_pos >= length) return -1;
    int64_t dst_n64 = input[dst_len_pos];
    if (dst_n64 < 0 || dst_n64 > MAX_TEXT) return -1;
    size_t dst_n = (size_t)dst_n64;
    if (length != 6 + src_n + dst_n) return -1;
    size_t dst_pos = dst_len_pos + 1, cost_pos = dst_pos + dst_n;
    for (size_t i = 0; i < src_n; ++i) if (input[1 + i] < 0 || input[1 + i] > 127) return -1;
    for (size_t j = 0; j < dst_n; ++j) if (input[dst_pos + j] < 0 || input[dst_pos + j] > 127) return -1;
    for (size_t k = 0; k < 4; ++k) if (input[cost_pos + k] < -1000 || input[cost_pos + k] > 1000) return -1;
    int64_t copy_cost=input[cost_pos], replace_cost=input[cost_pos+1];
    int64_t delete_cost=input[cost_pos+2], insert_cost=input[cost_pos+3];
    size_t rows=src_n+1, cols=dst_n+1, cells=rows*cols;
    int64_t dp[MAX_CELLS], code[MAX_CELLS], ca[MAX_CELLS], cb[MAX_CELLS];
    for (size_t i=0;i<cells;++i) { dp[i]=0; code[i]=0; ca[i]=0; cb[i]=0; }
    for (size_t j=1;j<cols;++j) { size_t x=j; dp[x]=dp[x-1]+insert_cost; code[x]=4; cb[x]=input[dst_pos+j-1]; }
    for (size_t i=1;i<rows;++i) { size_t x=i*cols; dp[x]=dp[x-cols]+delete_cost; code[x]=3; ca[x]=input[i]; }
    for (size_t i=1;i<rows;++i) for (size_t j=1;j<cols;++j) {
        size_t x=i*cols+j, up=x-cols, left=x-1, diag=up-1;
        int64_t a=input[i], b=input[dst_pos+j-1];
        int64_t best=dp[diag]+(a==b?copy_cost:replace_cost);
        int64_t op=a==b?1:2, aa=a, bb=a==b?0:b;
        int64_t deletion=dp[up]+delete_cost;
        if (deletion<best) { best=deletion; op=3; aa=a; bb=0; }
        int64_t insertion=dp[left]+insert_cost;
        if (insertion<best) { best=insertion; op=4; aa=0; bb=b; }
        dp[x]=best; code[x]=op; ca[x]=aa; cb[x]=bb;
    }
    size_t needed=32+cells*32;
    if (output==NULL || capacity<needed) return -2;
    size_t p=0;
    put_i64(output,&p,(int64_t)rows); put_i64(output,&p,(int64_t)cols);
    for (size_t x=0;x<cells;++x) put_i64(output,&p,dp[x]);
    put_i64(output,&p,(int64_t)rows); put_i64(output,&p,(int64_t)cols);
    for (size_t x=0;x<cells;++x) { put_i64(output,&p,code[x]); put_i64(output,&p,ca[x]); put_i64(output,&p,cb[x]); }
    return (int64_t)p;
}
