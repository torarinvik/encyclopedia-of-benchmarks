#include <stddef.h>
#include <stdint.h>
int64_t x932_padding(const int64_t *values,size_t length,uint8_t *output,size_t capacity){
 if(!values||length<1||length>257)return -1; if(values[0]<1||values[0]>64)return -1; size_t block=(size_t)values[0], n=length-1; for(size_t i=1;i<length;i++)if(values[i]<0||values[i]>255)return -1; size_t pad=block-(n%block), total=n+pad; if(total>capacity||!output)return -2; for(size_t i=0;i<n;i++)output[i]=(uint8_t)values[i+1]; for(size_t i=n;i<total-1;i++)output[i]=0; output[total-1]=(uint8_t)pad; return (int64_t)total;
}
