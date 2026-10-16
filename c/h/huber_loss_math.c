#include <stddef.h>
#include <stdint.h>
#define SCALE INT64_C(1000000)
#define MAX_COUNT INT64_C(64)
#define MAX_PARSED_COUNT INT64_C(65)
#define MAX_SAMPLE INT64_C(1000000000)
#define MAX_DELTA INT64_C(1000000000)
#define MAX_INPUT_LENGTH 133
#define INVALID_RESULT (-1.0e300)
double huber_loss_math(const int64_t *v, size_t n) {
    if (v == NULL || n < 3 || n > MAX_INPUT_LENGTH) return INVALID_RESULT;
    int64_t d=v[0], ac=v[1], pc=v[2];
    if (d<0 || d>MAX_DELTA || ac<0 || ac>MAX_PARSED_COUNT || pc<0 || pc>MAX_PARSED_COUNT) return INVALID_RESULT;
    if (n!=(size_t)(3+ac+pc) || ac>MAX_COUNT || pc>MAX_COUNT) return INVALID_RESULT;
    size_t a=(size_t)ac, p=(size_t)pc;
    for (size_t i=0;i<a+p;i++) if (v[3+i]<-MAX_SAMPLE || v[3+i]>MAX_SAMPLE) return INVALID_RESULT;
    double delta=(double)d/(double)SCALE, total=0.0;
    size_t pairs=a<p?a:p;
    for (size_t i=0;i<pairs;i++) {
        double diff=(double)v[3+i]/(double)SCALE-(double)v[3+a+i]/(double)SCALE;
        double residual=diff<0.0?-diff:diff;
        if (residual<=delta) total+=0.5*(diff*diff);
        else total+=delta*residual-0.5*delta;
    }
    return total;
}
