#include <stddef.h>
#include <stdint.h>

typedef struct { int64_t value; int balance; } Summary;
static Summary combine(Summary a, Summary b) {
    if (!a.balance) return b;
    if (!b.balance) return a;
    if (a.value == b.value) return (Summary){a.value, a.balance+b.balance};
    if (a.balance >= b.balance) return (Summary){a.value, a.balance-b.balance};
    return (Summary){b.value, b.balance-a.balance};
}
static uint64_t prefix_mask(size_t i) {
    return i == 64 ? UINT64_MAX : (UINT64_C(1) << i)-1;
}
static int bit_count(uint64_t bits) {
    int count = 0;
    while (bits) { bits &= bits-1; ++count; }
    return count;
}
static size_t value_slot(int64_t value, int64_t names[128], uint64_t masks[128], size_t *count) {
    for (size_t i = 0; i < *count; ++i) if (names[i] == value) return i;
    size_t i = (*count)++;
    names[i] = value; masks[i] = 0;
    return i;
}
int64_t dynamic_range_majority(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > 258 || input[0] < 1 || input[0] > 64 ||
        input[1] < 1 || input[1] > 64) return -1;
    size_t n = (size_t)input[0], q = (size_t)input[1];
    if (length != 2+n+3*q) return -1;
    for (size_t i = 0; i < n; ++i) if (input[2+i] < 0 || input[2+i] > 1000000000) return -1;
    size_t queries = 0;
    for (size_t i = 0; i < q; ++i) {
        int64_t op = input[2+n+3*i], a = input[3+n+3*i], b = input[4+n+3*i];
        if (op == 0) { if (a < 0 || a >= (int64_t)n || b < 0 || b > 1000000000) return -1; }
        else if (op == 1) { if (a < 0 || a >= b || b > (int64_t)n) return -1; ++queries; }
        else return -1;
    }
    if (!queries) return -1;
    if (!output || capacity < 8*queries) return -2;
    Summary tree[128] = {{0}};
    int64_t names[128] = {0}, data[64];
    uint64_t masks[128] = {0};
    size_t distinct = 0;
    for (size_t i = 0; i < n; ++i) {
        data[i] = input[2+i]; tree[64+i] = (Summary){data[i],1};
        size_t slot = value_slot(data[i], names, masks, &distinct);
        masks[slot] |= UINT64_C(1) << i;
    }
    for (size_t node = 63; node > 0; --node) tree[node] = combine(tree[2*node],tree[2*node+1]);
    size_t written = 0;
    for (size_t i = 0; i < q; ++i) {
        int64_t op = input[2+n+3*i], a = input[3+n+3*i], b = input[4+n+3*i];
        if (op == 0) {
            size_t p = (size_t)a, old = value_slot(data[p],names,masks,&distinct);
            size_t new_slot = value_slot(b,names,masks,&distinct);
            masks[old] &= ~(UINT64_C(1) << p); masks[new_slot] |= UINT64_C(1) << p;
            data[p] = b; size_t node = 64+p; tree[node] = (Summary){b,1};
            while ((node /= 2) != 0) tree[node] = combine(tree[2*node],tree[2*node+1]);
        } else {
            size_t lo = (size_t)a, hi = (size_t)b, l = lo+64, r = hi+64;
            Summary left = {0}, right = {0};
            while (l < r) {
                if (l & 1) left = combine(left,tree[l++]);
                if (r & 1) right = combine(tree[--r],right);
                l /= 2; r /= 2;
            }
            Summary candidate = combine(left,right);
            int64_t answer = -1;
            if (candidate.balance) {
                size_t slot = value_slot(candidate.value,names,masks,&distinct);
                uint64_t bits = masks[slot] & (prefix_mask(hi) ^ prefix_mask(lo));
                if (2*bit_count(bits) > (int)(hi-lo)) answer = candidate.value;
            }
            uint64_t bits = (uint64_t)answer;
            for (size_t j = 0; j < 8; ++j) output[8*written+j] = (uint8_t)(bits >> (8*j));
            ++written;
        }
    }
    return (int64_t)(8*written);
}
