#include <stddef.h>
#include <stdint.h>
#define MAX_ARRAY_LENGTH 256
static void reverse_bytes(uint8_t*a,size_t from,size_t to){while(from<to){uint8_t t=a[from];a[from++]=a[to];a[to--]=t;}}
int64_t char_array_left_rotation(const int64_t*input,size_t length,uint8_t*output,size_t capacity){if(input==NULL||length<2||length>MAX_ARRAY_LENGTH+3)return -1;if(input[0]<0||input[0]>MAX_ARRAY_LENGTH)return -1;size_t n=(size_t)input[0];if(input[1]<0||input[1]>(int64_t)n||length!=n+2)return -1;for(size_t i=0;i<n;i++)if(input[i+2]<0||input[i+2]>127)return -1;if(output==NULL||capacity<n)return -2;uint8_t a[MAX_ARRAY_LENGTH];for(size_t i=0;i<n;i++)a[i]=(uint8_t)input[i+2];if(input[1]>0)reverse_bytes(a,0,(size_t)input[1]-1);if((size_t)input[1]<n)reverse_bytes(a,(size_t)input[1],n-1);if(n>0)reverse_bytes(a,0,n-1);for(size_t i=0;i<n;i++)output[i]=a[i];return (int64_t)n;}
