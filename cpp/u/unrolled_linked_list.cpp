#include <cstddef>
#include <cstdint>
extern "C" int64_t unrolled_linked_list_benchmark(const int64_t* values, size_t length) {
    if (length > 1024) return -1;
    int64_t chunks[512][5]{}; size_t counts[512]{}, blocks=0;
    for (size_t i=0; i<length; ++i) {
        const int64_t value=values[i]; if(value < -1000000 || value > 1000000) return -1;
        if(blocks==0) { blocks=1; counts[0]=1; chunks[0][0]=value; }
        else if(counts[blocks-1] < 4) chunks[blocks-1][counts[blocks-1]++]=value;
        else { const size_t tail=blocks-1, keep=counts[tail]/2+1, moved=counts[tail]-keep;
            for(size_t j=0;j<moved;++j) chunks[blocks][j]=chunks[tail][keep+j];
            counts[tail]=keep; chunks[blocks][moved]=value; counts[blocks]=moved+1; ++blocks;
        }
    }
    int64_t sum=0; size_t index=0;
    for(size_t b=0;b<blocks;++b) for(size_t j=0;j<counts[b];++j,++index) sum+=int64_t(index+1)*(chunks[b][j]+1000000);
    return sum;
}
