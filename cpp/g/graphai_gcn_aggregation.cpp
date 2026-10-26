/* Clean-room bounded GCN normalized-neighbor aggregation. */
#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t graphai_gcn_aggregation(const double* input, std::size_t length,
                                                 double* output, std::size_t capacity) noexcept {
    constexpr std::size_t N=8, M=24, D=4, MAX_INPUT=4+3*N+M+N*D;
    if (!input || length < 7 || length > MAX_INPUT) return -1;
    for (std::size_t q=0;q<length;++q) if(!std::isfinite(input[q])) return -1;
    const double nv=input[0],mv=input[1],dv=input[2];
    if(std::trunc(nv)!=nv||std::trunc(mv)!=mv||std::trunc(dv)!=dv||nv<1||nv>N||mv<0||mv>M||dv<1||dv>D)return -1;
    const auto n=std::size_t(nv),m=std::size_t(mv),d=std::size_t(dv);
    if(length!=4+3*n+m+n*d)return -1;
    const std::size_t oa=3,ea=oa+n+1,la=ea+m,ra=la+n,fa=ra+n;
    if(input[oa]!=0||input[ea-1]!=double(m))return -1;
    std::size_t rowptr[N+1]{},colind[M]{};
    for(std::size_t i=0;i<=n;++i){double x=input[oa+i];if(std::trunc(x)!=x||x<0||x>m)return -1;rowptr[i]=std::size_t(x);if(i&&rowptr[i]<rowptr[i-1])return -1;}
    for(std::size_t e=0;e<m;++e){double x=input[ea+e];if(std::trunc(x)!=x||x<0||x>=n)return -1;colind[e]=std::size_t(x);}
    for(std::size_t i=0;i<n;++i)if(input[la+i]<-4||input[la+i]>4||input[ra+i]<-4||input[ra+i]>4)return -1;
    for(std::size_t q=0;q<n*d;++q)if(input[fa+q]<-8||input[fa+q]>8)return -1;
    const std::size_t required=n*d;if(!output||capacity<required)return -2;
    double staged[N*D]{};
    for(std::size_t src=0;src<n;++src)for(std::size_t e=rowptr[src];e<rowptr[src+1];++e){const auto dst=colind[e];const double w=input[la+src]*input[ra+dst];for(std::size_t k=0;k<d;++k)staged[src*d+k]+=w*input[fa+dst*d+k];}
    for(std::size_t q=0;q<required;++q)output[q]=staged[q];return std::int64_t(required);
}
