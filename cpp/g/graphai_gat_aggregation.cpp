/* Clean-room bounded GraphAIBench GAT attention aggregation. */
#include <cmath>
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t graphai_gat_aggregation(const double* input,std::size_t length,double* output,std::size_t capacity) noexcept{
    constexpr std::size_t N=8,M=24,D=4,MAX_INPUT=4+N+M+2*D+N*D;
    if(!input||length<3||length>MAX_INPUT)return -1;for(std::size_t q=0;q<length;++q)if(!std::isfinite(input[q]))return -1;
    double nv=input[0],mv=input[1],dv=input[2];if(std::trunc(nv)!=nv||std::trunc(mv)!=mv||std::trunc(dv)!=dv||nv<1||nv>N||mv<0||mv>M||dv<1||dv>D)return -1;
    auto n=std::size_t(nv),m=std::size_t(mv),d=std::size_t(dv);if(length!=4+n+m+2*d+n*d)return -1;
    std::size_t rp=3,ci=rp+n+1,al=ci+m,ar=al+d,xf=ar+d;if(input[rp]!=0||input[ci-1]!=double(m))return -1;
    std::size_t rows[N+1]{},cols[M]{};for(std::size_t i=0;i<=n;++i){double x=input[rp+i];if(std::trunc(x)!=x||x<0||x>m)return -1;rows[i]=std::size_t(x);if(i&&rows[i]<rows[i-1])return -1;}
    for(std::size_t e=0;e<m;++e){double x=input[ci+e];if(std::trunc(x)!=x||x<0||x>=n)return -1;cols[e]=std::size_t(x);}
    for(std::size_t q=al;q<length;++q)if(input[q]<-8||input[q]>8)return -1;
    const auto required=n*d;if(!output||capacity<required)return -2;double staged[N*D]{},scores[M]{},weights[M]{};
    for(std::size_t src=0;src<n;++src){auto begin=rows[src],end=rows[src+1];if(begin==end)continue;double maximum=-INFINITY;
        for(auto e=begin;e<end;++e){auto dst=cols[e];double score=0;for(std::size_t k=0;k<d;++k)score+=input[al+k]*input[xf+src*d+k];for(std::size_t k=0;k<d;++k)score+=input[ar+k]*input[xf+dst*d+k];scores[e]=score>0?score:0.2*score;if(scores[e]>maximum)maximum=scores[e];}
        double total=0;for(auto e=begin;e<end;++e){weights[e]=std::exp(scores[e]-maximum);total+=weights[e];}
        for(auto e=begin;e<end;++e){auto dst=cols[e];double scale=weights[e]/total;for(std::size_t k=0;k<d;++k)staged[src*d+k]+=scale*input[xf+dst*d+k];}
    }
    for(std::size_t q=0;q<required;++q)output[q]=staged[q];return std::int64_t(required);
}
