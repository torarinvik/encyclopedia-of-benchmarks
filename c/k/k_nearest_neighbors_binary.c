#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 8
#define MAX_POINTS 128

int64_t k_nearest_neighbors_binary(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3) return -1;
    const int64_t dimension64=input[0], count64=input[1], k64=input[2];
    if (dimension64 < 1 || dimension64 > MAX_DIMENSION || count64 < 1 || count64 > MAX_POINTS ||
        k64 < 1 || k64 > count64 || k64 % 2 == 0 ||
        length != 3 + (size_t)dimension64 + (size_t)count64 * ((size_t)dimension64 + 1)) return -1;
    const size_t dimension=(size_t)dimension64, count=(size_t)count64, k=(size_t)k64;
    for (size_t axis=0;axis<dimension;++axis)
        if (input[3+axis] < -1000 || input[3+axis] > 1000) return -1;
    int64_t distances[MAX_POINTS], labels[MAX_POINTS];
    for (size_t point=0;point<count;++point) {
        const size_t base=3+dimension+point*(dimension+1);
        int64_t distance=0;
        for (size_t axis=0;axis<dimension;++axis) {
            const int64_t coordinate=input[base+axis];
            if (coordinate < -1000 || coordinate > 1000) return -1;
            const int64_t delta=coordinate-input[3+axis];
            distance+=delta*delta;
        }
        const int64_t label=input[base+dimension];
        if (label != 0 && label != 1) return -1;
        for (size_t prior=0;prior<point;++prior) if (distances[prior]==distance) return -1;
        distances[point]=distance;labels[point]=label;
    }
    for (size_t i=1;i<count;++i) {
        const int64_t distance=distances[i], label=labels[i];
        size_t j=i;
        while (j>0 && distances[j-1]>distance) { distances[j]=distances[j-1];labels[j]=labels[j-1];--j; }
        distances[j]=distance;labels[j]=label;
    }
    int64_t ones=0;
    for (size_t i=0;i<k;++i) ones+=labels[i];
    const int64_t prediction=ones>(int64_t)(k/2);
    if (output==NULL || capacity<8) return -2;
    const uint64_t bits=(uint64_t)prediction;
    for(size_t byte=0;byte<8;++byte)output[byte]=(uint8_t)(bits>>(8*byte));
    return 8;
}
