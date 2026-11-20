/* Independently authored draft; not compiled or run. */
#include <stddef.h>
#include <stdint.h>
int64_t circle_circle_intersection_symbolic(const int64_t *v, size_t n, uint8_t *out, size_t cap) {
    if (!v || n != 6) return -1;
    for (size_t i=0;i<6;++i) if (v[i] < -1000 || v[i] > 1000) return -1;
    if (v[2] < 1 || v[5] < 1) return -1;
    const int64_t dx=v[3]-v[0], dy=v[4]-v[1], d=dx*dx+dy*dy;
    int64_t words[7]={0}; size_t count=1;
    if (!d) words[0]=v[2]==v[5] ? 3 : 0;
    else {
        const int64_t t=d+v[2]*v[2]-v[5]*v[5], h=4*v[2]*v[2]*d-t*t;
        if (h>=0) {
            const int64_t den=2*d; count=7;
            words[0]=h==0 ? 1 : 2; words[1]=den*v[0]+dx*t; words[2]=den*v[1]+dy*t;
            words[3]=den; words[4]=-dy; words[5]=dx; words[6]=h;
        }
    }
    size_t needed=8*count;
    if (!out || cap<needed) return -2;
    for (size_t i=0;i<count;++i) {
        uint64_t bits=(uint64_t)words[i];
        for (size_t j=0;j<8;++j) out[8*i+j]=(uint8_t)(bits>>(8*j));
    }
    return (int64_t)needed;
}
