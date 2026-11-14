/* Uncompiled and unexecuted weighted-binary-search draft. */
#include <stddef.h>
#include <stdint.h>
typedef struct { int64_t score; int count; } wqs_state;
static wqs_state evaluate(const int64_t *weights, size_t n, int64_t penalty) {
    wqs_state two = {0,0}, one = {0,0};
    for (size_t i = 0; i < n; ++i) {
        wqs_state take = {two.score+weights[i]-penalty, two.count+1};
        wqs_state current = take.score > one.score ||
            (take.score == one.score && take.count > one.count) ? take : one;
        two = one; one = current;
    }
    return one;
}
int64_t wqs_path_independent_set(const int64_t *input, size_t length) {
    if (!input || length < 2 || length > 130) return -1000000000;
    if (input[0] < 0 || input[0] > 128 || input[1] < 0 || input[1] > (input[0]+1)/2) return -1000000000;
    size_t n = (size_t)input[0];
    if (length != n+2) return -1000000000;
    for (size_t i = 0; i < n; ++i) if (input[2+i] < -1000 || input[2+i] > 1000) return -1000000000;
    int64_t low = -256001, high = 256001;
    while (low < high) {
        int64_t middle = low+(high-low+1)/2;
        if (evaluate(input+2, n, middle).count >= input[1]) low = middle;
        else high = middle-1;
    }
    return evaluate(input+2, n, low).score + low*input[1];
}
