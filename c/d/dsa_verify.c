#include <stddef.h>
#include <stdint.h>
#define MAX_MSG 8
static int prime(int64_t n){if(n<2)return 0;for(int64_t d=2;d*d<=n;d++)if(n%d==0)return 0;return 1;}
static int64_t modpow(int64_t a,int64_t e,int64_t m){int64_t r=1;a%=m;while(e>0){if(e&1)r=r*a%m;a=a*a%m;e>>=1;}return r;}
int64_t dsa_verify(const int64_t*v,size_t n){if(!v||n<7||n>15)return -1;int64_t p=v[0],q=v[1],g=v[2],y=v[3],r=v[4],s=v[5],ml=v[6];if(ml<0||ml>MAX_MSG||n!=(size_t)(7+ml))return -1;if(p<5||p>251||!prime(p)||q<2||q>=p||(p-1)%q||!prime(q))return -1;if(g<2||g>=p||modpow(g,q,p)!=1||y<1||y>=p||modpow(y,q,p)!=1||r<1||r>=q||s<1||s>=q)return -1;int64_t h=0;for(size_t i=0;i<(size_t)ml;i++){if(v[7+i]<0||v[7+i]>255)return -1;h=(h*256+v[7+i])%q;}int64_t w=modpow(s,q-2,q),u1=(int64_t)((h*w)%q),u2=(r*w)%q;return (((modpow(g,u1,p)*modpow(y,u2,p))%p)%q)==r;}
