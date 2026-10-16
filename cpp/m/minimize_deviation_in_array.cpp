#include <cstddef>
#include <cstdint>
static void push(std::int64_t*h,std::size_t&n,std::int64_t x){auto i=n++;while(i&&h[(i-1)/2]<x){h[i]=h[(i-1)/2];i=(i-1)/2;}h[i]=x;}
static std::int64_t pop(std::int64_t*h,std::size_t&n){auto top=h[0],x=h[--n];std::size_t i=0;while(2*i+1<n){auto c=2*i+1;if(c+1<n&&h[c+1]>h[c])++c;if(h[c]<=x)break;h[i]=h[c];i=c;}if(n)h[i]=x;return top;}
extern "C" std::int64_t minimize_deviation_in_array(const std::int64_t*v,std::size_t n)noexcept{if(!v||n<2||n>65||v[0]<1||v[0]>64||n!=static_cast<std::size_t>(v[0])+1)return -1;std::size_t count=static_cast<std::size_t>(v[0]),hn=0;std::int64_t h[64],low=INT64_MAX;for(std::size_t i=0;i<count;i++){auto x=v[i+1];if(x<1||x>1000000)return -1;if(x&1)x*=2;if(x<low)low=x;push(h,hn,x);}auto best=h[0]-low;while((h[0]&1)==0){auto x=pop(h,hn)/2;if(x<low)low=x;push(h,hn,x);auto d=h[0]-low;if(d<best)best=d;}return best;}
