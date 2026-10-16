#include <stddef.h>
#include <stdint.h>
int64_t inversions(const int64_t *values, size_t length) { if(length>1024||(length&&values==NULL))return -1; for(size_t i=0;i<length;i++)if(values[i]<INT32_MIN||values[i]>INT32_MAX)return -1; int64_t count=0; for(size_t i=0;i<length;i++)for(size_t j=i+1;j<length;j++)if(values[i]>values[j])count++; return count; }
