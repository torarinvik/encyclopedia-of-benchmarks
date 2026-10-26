/* Clean-room deterministic projection of GraphAIBench's three-hop sampler. */
#include <cmath>
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t graphai_frontier_sampler(const double* input,std::size_t length,double* output,std::size_t capacity) noexcept{
    constexpr std::size_t N=8,M=24,R=4,MAX_INPUT=4+N+M+22*R;
    if(!input||length<3||length>MAX_INPUT)return -1;for(std::size_t q=0;q<length;++q)if(!std::isfinite(input[q]))return -1;
    double nv=input[0],mv=input[1],rv=input[2];if(std::trunc(nv)!=nv||std::trunc(mv)!=mv||std::trunc(rv)!=rv||nv<1||nv>N||mv<0||mv>M||rv<1||rv>R)return -1;
    auto n=std::size_t(nv),m=std::size_t(mv),r=std::size_t(rv),required=22*r;if(length!=4+n+m+22*r)return -1;
    std::size_t root_at=3,row_at=root_at+r,col_at=row_at+n+1,choice_at=col_at+m;std::size_t rows[N+1]{},cols[M]{},front[R*12]{},next[R*12]{};double staged[R*22]{};
    for(std::size_t i=0;i<r;++i){double x=input[root_at+i];if(std::trunc(x)!=x||x<0||x>=n)return -1;front[i]=std::size_t(x);staged[i]=x;}
    if(input[row_at]!=0||input[col_at-1]!=double(m))return -1;
    for(std::size_t i=0;i<=n;++i){double x=input[row_at+i];if(std::trunc(x)!=x||x<0||x>m)return -1;rows[i]=std::size_t(x);if(i&&rows[i]<rows[i-1])return -1;}
    for(std::size_t e=0;e<m;++e){double x=input[col_at+e];if(std::trunc(x)!=x||x<0||x>=n)return -1;cols[e]=std::size_t(x);}
    if(!output||capacity<required)return -2;
    const std::size_t fanouts[3]={3,2,2};std::size_t front_size=r,choice=0,out_at=r;
    for(std::size_t round=0;round<3;++round){auto next_size=front_size*fanouts[round];for(std::size_t i=0;i<front_size;++i){auto parent=front[i],begin=rows[parent],degree=rows[parent+1]-begin;if(degree==0)return -1;
        for(std::size_t j=0;j<fanouts[round];++j){double x=input[choice_at+choice++];if(std::trunc(x)!=x||x<0||x>=degree)return -1;auto v=cols[begin+std::size_t(x)];next[i*fanouts[round]+j]=v;staged[out_at++]=double(v);}}
        for(std::size_t i=0;i<next_size;++i)front[i]=next[i];front_size=next_size;}
    if(choice!=21*r||out_at!=required)return -1;for(std::size_t q=0;q<required;++q)output[q]=staged[q];return std::int64_t(required);
}
