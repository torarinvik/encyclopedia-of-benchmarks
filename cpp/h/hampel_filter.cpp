/* Three-sample Java Hampel filter; emit integral filtered samples as LE i64. */
#include <cstddef>
#include <cstdint>
namespace {
constexpr std::size_t window=3;
void insert_sorted(double *a,std::size_t &size,double value){std::size_t p=0;while(p<size&&a[p]<value)++p;for(std::size_t j=size;j>p;--j)a[j]=a[j-1];a[p]=value;++size;}
void remove_sorted(double *a,std::size_t &size,double value){std::size_t p=0;while(p<size&&a[p]!=value)++p;if(p==size)return;for(std::size_t j=p+1;j<size;++j)a[j-1]=a[j];--size;}
double median(const double *a,std::size_t size){const auto m=size/2;return size%2?a[m]:0.5*(a[m-1]+a[m]);}
double mad(const double *a,std::size_t size,double med){std::size_t split=0;while(split<size&&a[split]<=med)++split;int left=static_cast<int>(split)-1;std::size_t right=split;double d[window];for(std::size_t i=0;i<size;++i){bool take=right>=size||(left>=0&&med-a[left]<=a[right]-med);if(take){d[i]=med-a[left];--left;}else{d[i]=a[right]-med;++right;}}const auto m=size/2;return size%2?d[m]:0.5*(d[m-1]+d[m]);}
void put_i64_le(std::uint8_t*out,std::size_t at,std::int64_t value){const auto bits=static_cast<std::uint64_t>(value);for(std::size_t b=0;b<8;++b)out[at+b]=static_cast<std::uint8_t>(bits>>(8*b));}
}
extern "C" std::int64_t hampel_filter(const std::int64_t*input,std::size_t length,std::uint8_t*output,std::size_t capacity) noexcept{
 if(!input||length<1||input[0]<0||input[0]>128||length!=static_cast<std::size_t>(input[0])+1)return -1;const auto n=static_cast<std::size_t>(input[0]);for(std::size_t i=0;i<n;++i)if(input[i+1]<-1000||input[i+1]>1000)return -1;if(capacity<n*8||(n>0&&!output))return -2;
 double arrival[window]={0},sorted[window]={0};std::size_t size=0,oldest=0;
 for(std::size_t i=0;i<n;++i){const double value=static_cast<double>(input[i+1]);if(size==window)remove_sorted(sorted,size,arrival[oldest]);insert_sorted(sorted,size,value);arrival[oldest]=value;oldest=(oldest+1)%window;const double med=median(sorted,size),mdev=mad(sorted,size,med),scaled=3.0*1.4826*mdev;const double distance=value>=med?value-med:med-value;const double filtered=distance>scaled?med:value;put_i64_le(output,i*8,static_cast<std::int64_t>(filtered));}
 return static_cast<std::int64_t>(n*8);
}
