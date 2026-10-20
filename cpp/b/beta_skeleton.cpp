// Bounded beta=2 lune graph adapted from ParGeo; see benchmarks/b/beta_skeleton/LICENSE.txt.
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t beta_skeleton(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t capacity){
    if(input==nullptr||length<3||length>65)return -1;auto n0=input[0];if(n0<1||n0>32||length!=1+2*static_cast<std::size_t>(n0))return -1;int n=static_cast<int>(n0);std::int64_t x[32]{},y[32]{};
    for(int i=0;i<n;i++){x[i]=input[1+2*i];y[i]=input[2+2*i];if(x[i]<-1000||x[i]>1000||y[i]<-1000||y[i]>1000)return -1;for(int j=0;j<i;j++)if(x[i]==x[j]&&y[i]==y[j])return -1;}
    std::uint8_t edges[992];std::size_t count=0;
    for(int i=0;i<n;i++)for(int j=i+1;j<n;j++){auto dx=x[i]-x[j],dy=y[i]-y[j],d2=dx*dx+dy*dy;bool blocked=false;
        for(int k=0;k<n;k++)if(k!=i&&k!=j){auto aix=x[k]-x[i],aiy=y[k]-y[i],ajx=x[k]-x[j],ajy=y[k]-y[j];if(aix*aix+aiy*aiy<d2&&ajx*ajx+ajy*ajy<d2){blocked=true;break;}}
        if(!blocked){edges[count++]=static_cast<std::uint8_t>(i);edges[count++]=static_cast<std::uint8_t>(j);}
    }
    if(output==nullptr||capacity<count)return -2;for(std::size_t i=0;i<count;i++)output[i]=edges[i];return static_cast<std::int64_t>(count);
}
