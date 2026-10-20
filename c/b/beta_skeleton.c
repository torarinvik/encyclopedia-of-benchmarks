/* Bounded beta=2 lune graph; adapted from MIT-licensed ParGeo semantics. See benchmarks/b/beta_skeleton/LICENSE.txt. */
#include <stddef.h>
#include <stdint.h>
#define BS_MAX_N 32
#define BS_MAX_INPUT 65
#define BS_MAX_OUTPUT 992

int64_t beta_skeleton(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(!input||length<3||length>BS_MAX_INPUT)return -1;
    int64_t n0=input[0];if(n0<1||n0>BS_MAX_N||length!=1+2*(size_t)n0)return -1;
    size_t n=(size_t)n0;int64_t x[BS_MAX_N],y[BS_MAX_N];
    for(size_t i=0;i<n;i++){x[i]=input[1+2*i];y[i]=input[2+2*i];if(x[i]<-1000||x[i]>1000||y[i]<-1000||y[i]>1000)return -1;for(size_t j=0;j<i;j++)if(x[i]==x[j]&&y[i]==y[j])return -1;}
    uint8_t edges[BS_MAX_OUTPUT];size_t count=0;
    for(size_t i=0;i<n;i++)for(size_t j=i+1;j<n;j++){
        int64_t dx=x[i]-x[j],dy=y[i]-y[j],d2=dx*dx+dy*dy;int blocked=0;
        for(size_t k=0;k<n;k++)if(k!=i&&k!=j){int64_t aix=x[k]-x[i],aiy=y[k]-y[i],ajx=x[k]-x[j],ajy=y[k]-y[j];if(aix*aix+aiy*aiy<d2&&ajx*ajx+ajy*ajy<d2){blocked=1;break;}}
        if(!blocked){edges[count++]=(uint8_t)i;edges[count++]=(uint8_t)j;}
    }
    if(!output||capacity<count)return -2;for(size_t i=0;i<count;i++)output[i]=edges[i];return (int64_t)count;
}
