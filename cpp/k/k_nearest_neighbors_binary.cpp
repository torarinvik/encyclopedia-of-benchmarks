#include <cstddef>
#include <cstdint>

extern "C" std::int64_t k_nearest_neighbors_binary(const std::int64_t* input,std::size_t length,
                                                    std::uint8_t* output,std::size_t capacity) noexcept {
    if(input==nullptr||length<3)return -1;
    const std::int64_t d64=input[0],n64=input[1],k64=input[2];
    if(d64<1||d64>8||n64<1||n64>128||k64<1||k64>n64||k64%2==0||
       length!=3+static_cast<std::size_t>(d64)+static_cast<std::size_t>(n64)*(static_cast<std::size_t>(d64)+1))return -1;
    const auto d=static_cast<std::size_t>(d64),n=static_cast<std::size_t>(n64),k=static_cast<std::size_t>(k64);
    for(std::size_t axis=0;axis<d;++axis)if(input[3+axis]<-1000||input[3+axis]>1000)return -1;
    std::int64_t distance[128],label[128];
    for(std::size_t point=0;point<n;++point){const auto base=3+d+point*(d+1);std::int64_t sum=0;
        for(std::size_t axis=0;axis<d;++axis){const auto x=input[base+axis];if(x< -1000||x>1000)return -1;const auto delta=x-input[3+axis];sum+=delta*delta;}
        const auto y=input[base+d];if(y!=0&&y!=1)return -1;for(std::size_t prev=0;prev<point;++prev)if(distance[prev]==sum)return -1;distance[point]=sum;label[point]=y;
    }
    for(std::size_t i=1;i<n;++i){const auto dist=distance[i],class_id=label[i];std::size_t j=i;while(j>0&&distance[j-1]>dist){distance[j]=distance[j-1];label[j]=label[j-1];--j;}distance[j]=dist;label[j]=class_id;}
    std::int64_t ones=0;for(std::size_t i=0;i<k;++i)ones+=label[i];const std::int64_t prediction=ones>static_cast<std::int64_t>(k/2);
    if(output==nullptr||capacity<8)return -2;const std::uint64_t bits=static_cast<std::uint64_t>(prediction);for(std::size_t b=0;b<8;++b)output[b]=static_cast<std::uint8_t>(bits>>(8*b));return 8;
}
