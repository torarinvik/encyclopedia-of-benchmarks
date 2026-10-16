extern "C" {

#include <stddef.h>
#include <stdint.h>

static const double start[2] = {0.6, 0.4};
static const double trans[2][2] = {{0.7, 0.3}, {0.4, 0.6}};
static const double emit[2][3] = {{0.5, 0.4, 0.1}, {0.1, 0.3, 0.6}};
int64_t viterbi(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 1 || length > 64) return -1;
    for (size_t i=0;i<length;i++) if (input[i]<0 || input[i]>2) return -1;
    if (!output || capacity < length*8) return -2;
    double score[2], next[2]; int path[64][2];
    for (int s=0;s<2;s++) score[s]=start[s]*emit[s][input[0]];
    for (size_t t=1;t<length;t++) {
        for (int s=0;s<2;s++) {
            double a=score[0]*trans[0][s]*emit[s][input[t]];
            double b=score[1]*trans[1][s]*emit[s][input[t]];
            path[t][s]=(b>a)?1:0; next[s]=(b>a)?b:a;
        }
        score[0]=next[0]; score[1]=next[1];
    }
    int state=(score[1]>score[0])?1:0; int result[64]; result[length-1]=state;
    for (size_t t=length-1;t>0;t--) { state=path[t][state]; result[t-1]=state; }
    for(size_t i=0;i<length;i++) { uint64_t x=(uint64_t)(int64_t)result[i]; for(int b=0;b<8;b++) output[8*i+b]=(uint8_t)(x>>(8*b)); }
    return (int64_t)(length*8);
}

}
