#include <math.h>
#include <stddef.h>
#include <stdint.h>

static int64_t invalid(void) { return -1; }
int64_t elastic_collision2_d(const int64_t *v, size_t n) {
    if (!v || n != 12) return invalid();
    for (size_t i=0;i<12;i++) {
        if ((i==0||i==1||i==6||i==7) && (v[i] < -200000 || v[i] > 200000)) return invalid();
        if ((i==2||i==3||i==8||i==9) && (v[i] < -5000 || v[i] > 5000)) return invalid();
    }
    if (v[4]<1000||v[4]>100000||v[10]<1000||v[10]>100000||v[5]<1||v[5]>10000||v[11]<1||v[11]>10000) return invalid();
    double dx=(double)v[6]-(double)v[0], dy=(double)v[7]-(double)v[1], dist=hypot(dx,dy);
    if (dist==0.0) return invalid();
    double ox=(double)v[2], oy=(double)v[3];
    if (!(dist < (double)v[5]+(double)v[11])) {
        double nx=dx/dist, ny=dy/dist;
        double rv=((double)v[8]-v[2])*nx+((double)v[9]-v[3])*ny;
        if (rv<=0.0) {
            double j=-2.0*rv/(1.0/(double)v[4]+1.0/(double)v[10]);
            ox-=j*nx/(double)v[4]; oy-=j*ny/(double)v[4];
        }
    }
    int64_t qx=(int64_t)floor(ox+0.5), qy=(int64_t)floor(oy+0.5);
    if (qx < -32768 || qx > 32767 || qy < -32768 || qy > 32767) return invalid();
    return ((qx & 0xffff) << 16) | (qy & 0xffff);
}
