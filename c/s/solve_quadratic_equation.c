#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#define LIMIT INT64_C(1000000)
static void put_f64_le(uint8_t *out,size_t offset,double value){uint64_t bits;memcpy(&bits,&value,8);for(size_t b=0;b<8;++b)out[offset+b]=(uint8_t)(bits>>(8*b));}
int64_t solve_quadratic_equation(const int64_t *values,size_t length,uint8_t *output,size_t capacity){
    if(values==NULL||length!=2)return -1;
    int64_t pi=values[0],qi=values[1];if(pi < -LIMIT||pi>LIMIT||qi < -LIMIT||qi>LIMIT)return -1;
    double p=(double)pi,q=(double)qi;double root=sqrt(p*p/4.0-q);
    if(root!=root)return 0;
    double x1=-p/2.0-root,x2=-p/2.0+root;
    if(x1==x2){if(output==NULL||capacity<8)return -2;put_f64_le(output,0,x1);return 1;}
    if(output==NULL||capacity<16)return -2;put_f64_le(output,0,x1);put_f64_le(output,8,x2);return 2;
}
