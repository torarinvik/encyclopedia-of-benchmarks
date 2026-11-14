#include <stddef.h>
#include <stdint.h>

static int64_t projection(const int64_t *input, size_t i, int64_t dx, int64_t dy, int axis) {
    int64_t x=input[1+2*i], y=input[2+2*i];
    return axis==2 ? dx*y-dy*x : dx*x+dy*y;
}
static int64_t gcd_value(int64_t a, int64_t b) {
    while (b) { int64_t r=a%b; a=b; b=r; }
    return a;
}
int64_t minimum_area_enclosing_rectangle(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length<7 || length>34 || input[0]<3 || input[0]>16) return -1;
    size_t n=(size_t)input[0];
    if (length!=1+2*n) return -1;
    for (size_t i=1; i<length; ++i) if (input[i]< -100 || input[i]>100) return -1;
    for (size_t i=0; i<n; ++i) {
        size_t next=(i+1)%n;
        int64_t ax=input[1+2*i], ay=input[2+2*i];
        int64_t dx=input[1+2*next]-ax, dy=input[2+2*next]-ay;
        for (size_t j=0; j<n; ++j) if (j!=i && j!=next) {
            if (dx*(input[2+2*j]-ay)-dy*(input[1+2*j]-ax)<=0) return -1;
        }
    }
    int64_t first_dx=input[3]-input[1], first_dy=input[4]-input[2];
    size_t supports[3]={0};
    for (size_t i=1; i<n; ++i) for (int axis=0; axis<3; ++axis) {
        int64_t candidate=projection(input,i,first_dx,first_dy,axis);
        int64_t current=projection(input,supports[axis],first_dx,first_dy,axis);
        if ((axis==1 && candidate<current) || (axis!=1 && candidate>current)) supports[axis]=i;
    }
    int64_t best_num=0, best_den=1;
    for (size_t i=0; i<n; ++i) {
        size_t next=(i+1)%n;
        int64_t ax=input[1+2*i], ay=input[2+2*i];
        int64_t dx=input[1+2*next]-ax, dy=input[2+2*next]-ay;
        for (int axis=0; axis<3; ++axis) for (size_t steps=0; steps<n; ++steps) {
            size_t following=(supports[axis]+1)%n;
            int64_t current=projection(input,supports[axis],dx,dy,axis);
            int64_t candidate=projection(input,following,dx,dy,axis);
            if ((axis==1 && candidate<=current) || (axis!=1 && candidate>=current)) supports[axis]=following;
            else break;
        }
        int64_t span=projection(input,supports[0],dx,dy,0)-projection(input,supports[1],dx,dy,1);
        int64_t thickness=projection(input,supports[2],dx,dy,2)-(dx*ay-dy*ax);
        int64_t numerator=span*thickness, denominator=dx*dx+dy*dy;
        if (i==0 || numerator*best_den<best_num*denominator) { best_num=numerator; best_den=denominator; }
    }
    int64_t divisor=gcd_value(best_num,best_den);
    int64_t words[2]={best_num/divisor,best_den/divisor};
    if (!output || capacity<16) return -2;
    for (size_t i=0; i<2; ++i) for (size_t b=0; b<8; ++b)
        output[8*i+b]=(uint8_t)((uint64_t)words[i]>>(8*b));
    return 16;
}
