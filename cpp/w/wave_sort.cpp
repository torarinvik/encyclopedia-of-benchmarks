// Portable signed-32-bit wave arrangement.
#include <cstddef>
#include <cstdint>
static constexpr std::size_t MAX_ARRAY_LENGTH=4096;
static void sift_down(std::int64_t* v,std::size_t root,std::size_t end){while(root<end/2){std::size_t child=root*2+1;if(child+1<end&&v[child]<v[child+1])++child;if(v[root]>=v[child])break;auto t=v[root];v[root]=v[child];v[child]=t;root=child;}}

extern "C" std::int64_t wave_sort(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t output_capacity) noexcept {
    if(length>MAX_ARRAY_LENGTH||(length!=0&&input==nullptr))return -1;
    std::int64_t values[MAX_ARRAY_LENGTH];for(std::size_t i=0;i<length;++i){if(input[i]<INT32_MIN||input[i]>INT32_MAX)return -1;values[i]=input[i];}
    const std::size_t bytes=length*4;if(output_capacity<bytes||(bytes!=0&&output==nullptr))return -2;
        for(std::size_t start=length/2;start>0;){--start;sift_down(values,start,length);}
    for(std::size_t end=length;end>1;){auto t=values[0];values[0]=values[end-1];values[end-1]=t;--end;sift_down(values,0,end);}
    for(std::size_t i=0;i+1<length;i+=2){auto t=values[i];values[i]=values[i+1];values[i+1]=t;}

    for(std::size_t i=0;i<length;++i){const std::uint32_t bits=static_cast<std::uint32_t>(static_cast<std::int32_t>(values[i]));for(std::size_t b=0;b<4;++b)output[i*4+b]=static_cast<std::uint8_t>(bits>>(b*8));}
    return static_cast<std::int64_t>(length);
}
