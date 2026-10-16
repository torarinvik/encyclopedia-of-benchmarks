#include <stddef.h>
#include <stdint.h>
static size_t append_num(uint8_t*b,size_t p,int64_t x){uint8_t d[3];size_t n=0;do{d[n++]=(uint8_t)('0'+x%10);x/=10;}while(x);while(n)b[p++]=d[--n];return p;}
int64_t node_neighbors(const int64_t*v,size_t n,uint8_t*out,size_t cap){if(!v||n<2||v[0]<0||v[0]>64||v[1]<0||v[1]>63||n!=2+2*(size_t)v[0])return -1;uint8_t seen[64]={0},b[192];size_t used=0;for(size_t i=0;i<(size_t)v[0];i++){int64_t a=v[2+2*i],c=v[3+2*i];if(a<0||a>63||c<0||c>63)return -1;int64_t x=a==v[1]?c:c==v[1]?a:-1;if(x>=0&&!seen[x]){seen[x]=1;if(used)b[used++]=',';used=append_num(b,used,x);}}if(used>cap||(used&&!out))return -2;for(size_t i=0;i<used;i++)out[i]=b[i];return (int64_t)used;}
