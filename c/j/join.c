#include <stddef.h>
#include <stdint.h>
#define MAX_INPUT 2114
#define MAX_OUTPUT 3040
int64_t join(const int64_t *v,size_t n,uint8_t *out,size_t cap){
 if(!v||n<2||n>2115)return -1;int64_t sl=v[0],count=v[1];if(sl<0||sl>32||count<0||count>32)return -1;size_t cursor=2;if((size_t)sl>n-cursor)return -1;uint8_t sep[32],result[MAX_OUTPUT];for(size_t i=0;i<(size_t)sl;i++){int64_t x=v[cursor++];if(x<0||x>127)return -1;sep[i]=(uint8_t)x;}size_t written=0;
 for(size_t item=0;item<(size_t)count;item++){if(cursor>=n)return -1;int64_t len=v[cursor++];if(len<0||len>64||(size_t)len>n-cursor)return -1;if(item>0)for(size_t j=0;j<(size_t)sl;j++)result[written++]=sep[j];for(size_t j=0;j<(size_t)len;j++){int64_t x=v[cursor++];if(x<0||x>127)return -1;result[written++]=(uint8_t)x;}}if(cursor!=n)return -1;if(!out||cap<written)return -2;for(size_t i=0;i<written;i++)out[i]=result[i];return (int64_t)written;
}
