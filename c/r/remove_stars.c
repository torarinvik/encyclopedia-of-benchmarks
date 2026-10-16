#include <stddef.h>
#include <stdint.h>
#define MAX_INPUT_LENGTH 4096
int64_t remove_stars(const int64_t *v,size_t n,uint8_t *out,size_t cap){
 if(!v||n<1||n>MAX_INPUT_LENGTH+1||v[0]<0||v[0]>MAX_INPUT_LENGTH||n!=(size_t)v[0]+1)return -1;
 size_t result=0;for(size_t i=0;i<(size_t)v[0];i++){int64_t c=v[i+1];if(c<0||c>127)return -1;if(c=='*'){if(result>0)result--;}else result++;}
 if(result>cap||(result>0&&!out))return -2;size_t w=0;for(size_t i=0;i<(size_t)v[0];i++){uint8_t c=(uint8_t)v[i+1];if(c=='*'){if(w>0)w--;}else out[w++]=c;}return (int64_t)w;
}
