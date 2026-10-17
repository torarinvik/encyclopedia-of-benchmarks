#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_operations = 256, max_input_length = 514, max_live_values = 64;
constexpr std::int64_t nil_sentinel = INT64_MIN;
void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) { const auto bits=static_cast<std::uint64_t>(value);for(std::size_t b=0;b<8;++b)output[offset+b]=static_cast<std::uint8_t>(bits>>(8*b)); }
void push_max(std::int32_t* h,std::size_t& n,std::int32_t x){std::size_t p=n++;while(p>0&&h[(p-1)/2]<x){auto q=(p-1)/2;h[p]=h[q];p=q;}h[p]=x;}
std::int32_t pop_max(std::int32_t* h,std::size_t& n){auto r=h[0],x=h[--n];if(n==0)return r;std::size_t p=0;while(2*p+1<n){auto c=2*p+1;if(c+1<n&&h[c+1]>h[c])++c;if(h[c]<=x)break;h[p]=h[c];p=c;}h[p]=x;return r;}
void push_min(std::int32_t* h,std::size_t& n,std::int32_t x){std::size_t p=n++;while(p>0&&h[(p-1)/2]>x){auto q=(p-1)/2;h[p]=h[q];p=q;}h[p]=x;}
std::int32_t pop_min(std::int32_t* h,std::size_t& n){auto r=h[0],x=h[--n];if(n==0)return r;std::size_t p=0;while(2*p+1<n){auto c=2*p+1;if(c+1<n&&h[c+1]<h[c])++c;if(h[c]>=x)break;h[p]=h[c];p=c;}h[p]=x;return r;}
}

extern "C" std::int64_t median_heap(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t capacity){
    if(input==nullptr||length<1||length>max_input_length)return -1;
    const auto operation_count_value=input[0];if(operation_count_value<0||operation_count_value>static_cast<std::int64_t>(max_operations)||length!=1+2*static_cast<std::size_t>(operation_count_value))return -1;
    const auto count=static_cast<std::size_t>(operation_count_value);std::int32_t lower[max_live_values],upper[max_live_values];std::size_t lc=0,uc=0;std::int64_t results[max_operations];
    for(std::size_t i=0;i<count;++i){const auto op=input[1+2*i],arg=input[2+2*i];
        if(op==0){if(arg<INT32_MIN||arg>INT32_MAX||lc+uc>=max_live_values)return -1;const auto x=static_cast<std::int32_t>(arg);
            if(lc==0)push_max(lower,lc,x);else if(x<lower[0]){push_max(lower,lc,x);if(lc-uc>1)push_min(upper,uc,pop_max(lower,lc));}else{push_min(upper,uc,x);if(lc<uc)push_max(lower,lc,pop_min(upper,uc));}results[i]=nil_sentinel;
        }else if(op>=1&&op<=4){if(arg!=0)return -1;if(op==1)results[i]=lc?lower[0]:nil_sentinel;
            else if(op==2){if(lc==0)results[i]=nil_sentinel;else{results[i]=pop_max(lower,lc);if(lc<uc)push_max(lower,lc,pop_min(upper,uc));}}
            else if(op==3)results[i]=static_cast<std::int64_t>(lc+uc);else results[i]=lc==0?1:0;
        }else return -1;
    }
    const auto output_bytes=count*8;if(output==nullptr||capacity<output_bytes)return -2;for(std::size_t i=0;i<count;++i)store_i64_le(output,8*i,results[i]);return static_cast<std::int64_t>(output_bytes);
}
