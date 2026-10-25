/* Fixed-table improved Perlin gradient noise for one bounded 3D point. */
#include <cmath>

namespace {
constexpr int permutation[256] = {
    151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,
    140,36,103,30,69,142,8,99,37,240,21,10,23,190,6,148,
    247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,
    57,177,33,88,237,149,56,87,174,20,125,136,171,168,68,175,
    74,165,71,134,139,48,27,166,77,146,158,231,83,111,229,122,
    60,211,133,230,220,105,92,41,55,46,245,40,244,102,143,54,
    65,25,63,161,1,216,80,73,209,76,132,187,208,89,18,169,
    200,196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,
    52,217,226,250,124,123,5,202,38,147,118,126,255,82,85,212,
    207,206,59,227,47,16,58,17,182,189,28,42,223,183,170,213,
    119,248,152,2,44,154,163,70,221,153,101,155,167,43,172,9,
    129,22,39,253,19,98,108,110,79,113,224,232,178,185,112,104,
    218,246,97,228,251,34,242,193,238,210,144,12,191,179,162,241,
    81,51,145,235,249,14,239,107,49,192,214,31,181,199,106,157,
    184,84,204,176,115,121,50,45,127,4,150,254,138,236,205,93,
    222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180
};
double fade(double t) { return t*t*t*(t*(t*6.0-15.0)+10.0); }
double mix(double t,double a,double b) { return a+t*(b-a); }
double gradient(int h,double x,double y,double z) {
    int k=h&15; double u=k<8?x:y; double v=k<4?y:((k==12||k==14)?x:z);
    return ((k&1)==0?u:-u)+((k&2)==0?v:-v);
}
int lookup(int i) { return permutation[i&255]; }
}

extern "C" double improved_perlin_noise_3d(double x,double y,double z) noexcept {
    if (x!=x||y!=y||z!=z||x < -1000000.0||x > 1000000.0||
        y < -1000000.0||y > 1000000.0||z < -1000000.0||z > 1000000.0) return -1.0;
    const double fx=std::floor(x),fy=std::floor(y),fz=std::floor(z);
    const int ix=static_cast<int>(fx)&255,iy=static_cast<int>(fy)&255,iz=static_cast<int>(fz)&255;
    x-=fx;y-=fy;z-=fz;
    const double u=fade(x),v=fade(y),w=fade(z);
    const int a=lookup(ix)+iy,aa=lookup(a)+iz,ab=lookup(a+1)+iz;
    const int b=lookup(ix+1)+iy,ba=lookup(b)+iz,bb=lookup(b+1)+iz;
    return mix(w,
        mix(v,mix(u,gradient(lookup(aa),x,y,z),gradient(lookup(ba),x-1.0,y,z)),
                mix(u,gradient(lookup(ab),x,y-1.0,z),gradient(lookup(bb),x-1.0,y-1.0,z))),
        mix(v,mix(u,gradient(lookup(aa+1),x,y,z-1.0),gradient(lookup(ba+1),x-1.0,y,z-1.0)),
                mix(u,gradient(lookup(ab+1),x,y-1.0,z-1.0),gradient(lookup(bb+1),x-1.0,y-1.0,z-1.0))));
}
