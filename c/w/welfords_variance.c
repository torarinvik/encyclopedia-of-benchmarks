#include <stddef.h>
#include <stdint.h>
#define MAX_LENGTH 64
#define MAX_ABS_VALUE INT64_C(1000000)
#define INVALID_RESULT (-1.0e300)
double welfords_variance(const int64_t *values, size_t length) {
 if (!values || length < 2 || length > MAX_LENGTH) return INVALID_RESULT;
 double mean=0.0,m2=0.0;
 for(size_t i=0;i<length;i++){int64_t x=values[i];if(x < -MAX_ABS_VALUE || x > MAX_ABS_VALUE)return INVALID_RESULT;double delta=(double)x-mean;mean += delta/(double)(i+1);m2 += delta*((double)x-mean);}
 return m2/(double)(length-1);
}
