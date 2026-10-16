#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_COORDS 8192
static void reverse_points(int64_t *out, size_t start, size_t count) {
    for (size_t i = 0; i < count / 2; ++i) {
        size_t a = start + 2 * i, b = start + 2 * (count - 1 - i);
        int64_t x = out[a], y = out[a + 1]; out[a] = out[b]; out[a + 1] = out[b + 1]; out[b] = x; out[b + 1] = y;
    }
}
static size_t curve(int64_t x, int64_t y, int64_t side, int level, int angle, int64_t *out, size_t offset) {
    int64_t q = side / 4;
    int64_t p[4][2] = {{x+q,y+q},{x-q,y+q},{x-q,y-q},{x+q,y-q}};
    angle = ((angle % 4) + 4) % 4;
    int64_t r[4][2];
    for (int i=0;i<4;i++){r[i][0]=p[(i+angle)%4][0];r[i][1]=p[(i+angle)%4][1];}
    if(level==1){for(int i=0;i<4;i++){out[offset+2*i]=r[i][0];out[offset+2*i+1]=r[i][1];}return 4;}
    int64_t half=side/2; size_t n=curve(r[0][0],r[0][1],half,level-1,angle+1,out,offset); reverse_points(out,offset,n);
    size_t n1=curve(r[1][0],r[1][1],half,level-1,angle,out,offset+2*n);
    size_t n2=curve(r[2][0],r[2][1],half,level-1,angle,out,offset+2*(n+n1));
    size_t n3=curve(r[3][0],r[3][1],half,level-1,angle-1,out,offset+2*(n+n1+n2)); reverse_points(out,offset+2*(n+n1+n2),n3);
    return n+n1+n2+n3;
}
int64_t hilbert_curve(const int64_t *v,size_t n,uint8_t *out,size_t cap){
    if(!v||n!=2||v[0]<1||v[0]>6||v[1]<0||v[1]>3)return -1;
    size_t level=(size_t)v[0],points=(size_t)1<<(2*level),bytes=points*16;
    if(!out||cap<bytes)return -2;
    int64_t coords[MAX_COORDS];curve(0,0,(int64_t)1<<(level+1),(int)level,(int)v[1],coords,0);
    for(size_t i=0;i<points*2;i++){uint64_t bits;memcpy(&bits,&coords[i],8);for(size_t k=0;k<8;k++)out[i*8+k]=(uint8_t)(bits>>(8*k));}
    return (int64_t)bytes;
}
