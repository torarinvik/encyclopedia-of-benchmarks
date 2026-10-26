/* Clean-room bounded GraphAIBench collaborative-filtering SGD sweep. */
#include <cmath>
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t graphai_cf_sgd_sweep(const double* input,std::size_t length,double* output,std::size_t capacity) noexcept{
    constexpr std::size_t N=8,M=24,K=4,MAX_INPUT=7+N+2*M+N*K;
    if(!input||length<6||length>MAX_INPUT)return -1;for(std::size_t q=0;q<length;++q)if(!std::isfinite(input[q]))return -1;
    double uv=input[0],iv=input[1],mv=input[2],kv=input[3];if(std::trunc(uv)!=uv||std::trunc(iv)!=iv||std::trunc(mv)!=mv||std::trunc(kv)!=kv||uv<1||uv>7||iv<1||iv>7||mv<0||mv>M||kv<1||kv>K)return -1;
    auto users=std::size_t(uv),items=std::size_t(iv),n=users+items,m=std::size_t(mv),k=std::size_t(kv);double lambda=input[4],step=input[5];
    if(n>N||lambda<0||lambda>1||step<0||step>0.01||length!=7+n+2*m+n*k)return -1;
    std::size_t rp=6,ci=rp+n+1,ra=ci+m,la=ra+m;if(input[rp]!=0||input[ci-1]!=double(m))return -1;
    std::size_t rows[N+1]{},cols[M]{};for(std::size_t i=0;i<=n;++i){double x=input[rp+i];if(std::trunc(x)!=x||x<0||x>m)return -1;rows[i]=std::size_t(x);if(i&&rows[i]<rows[i-1])return -1;}
    for(std::size_t u=users;u<n;++u)if(rows[u]!=rows[u+1])return -1;
    for(std::size_t e=0;e<m;++e){double x=input[ci+e];if(std::trunc(x)!=x||x<users||x>=n)return -1;cols[e]=std::size_t(x);}
    for(std::size_t e=0;e<m;++e)if(input[ra+e]<-4||input[ra+e]>4)return -1;
    for(std::size_t q=0;q<n*k;++q)if(input[la+q]<-2||input[la+q]>2)return -1;
    const auto required=n*k;if(!output||capacity<required)return -2;double error[N*K]{},staged[N*K]{};
    for(std::size_t u=0;u<users;++u)for(auto e=rows[u];e<rows[u+1];++e){auto v=cols[e];double estimate=0;for(std::size_t j=0;j<k;++j)estimate+=input[la+u*k+j]*input[la+v*k+j];double delta=input[ra+e]-estimate;for(std::size_t j=0;j<k;++j)error[u*k+j]+=input[la+v*k+j]*delta;}
    for(std::size_t v=0;v<n;++v)for(std::size_t j=0;j<k;++j){auto q=v*k+j;staged[q]=input[la+q]+step*(-lambda*input[la+q]+error[q]);}
    for(std::size_t q=0;q<required;++q)output[q]=staged[q];return std::int64_t(required);
}
