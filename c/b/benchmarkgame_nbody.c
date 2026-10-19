/* Independent bounded port of Benchmark Game's classic five-body kernel. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

typedef struct { double x,y,z,vx,vy,vz,mass; } Body;
static void put_f64(uint8_t *out, size_t offset, double value) {
    uint64_t bits; memcpy(&bits, &value, sizeof(bits));
    for (size_t k=0;k<8;k++) out[offset+k]=(uint8_t)(bits>>(8*k));
}
static double energy(const Body *b) {
    double e=0.0;
    for (size_t i=0;i<5;i++) {
        e += 0.5*b[i].mass*(b[i].vx*b[i].vx+b[i].vy*b[i].vy+b[i].vz*b[i].vz);
        for (size_t j=i+1;j<5;j++) {
            double dx=b[i].x-b[j].x, dy=b[i].y-b[j].y, dz=b[i].z-b[j].z;
            double distance=sqrt(dx*dx+dy*dy+dz*dz);
            e -= (b[i].mass*b[j].mass)/distance;
        }
    }
    return e;
}
int64_t benchmarkgame_nbody(const int64_t *input,size_t length,uint8_t *output,size_t capacity) {
    if (!input || length!=1 || input[0]<0 || input[0]>1000) return -1;
    if (!output || capacity<16) return -2;
    const double pi=3.141592653589793, solar_mass=4*pi*pi, days=365.24;
    Body b[5]={
        {0,0,0,0,0,0,solar_mass},
        {4.84143144246472090e+00,-1.16032004402742839e+00,-1.03622044471123109e-01,
         1.66007664274403694e-03*days,7.69901118419740425e-03*days,-6.90460016972063023e-05*days,9.54791938424326609e-04*solar_mass},
        {8.34336671824457987e+00,4.12479856412430479e+00,-4.03523417114321381e-01,
         -2.76742510726862411e-03*days,4.99852801234917238e-03*days,2.30417297573763929e-05*days,2.85885980666130812e-04*solar_mass},
        {1.28943695621391310e+01,-1.51111514016986312e+01,-2.23307578892655734e-01,
         2.96460137564761618e-03*days,2.37847173959480950e-03*days,-2.96589568540237556e-05*days,4.36624404335156298e-05*solar_mass},
        {1.53796971148509165e+01,-2.59193146099879641e+01,1.79258772950371181e-01,
         2.68067772490389322e-03*days,1.62824170038242295e-03*days,-9.51592254519715870e-05*days,5.15138902046611451e-05*solar_mass}
    };
    double px=0.0,py=0.0,pz=0.0;
    for(size_t i=0;i<5;i++){px+=b[i].vx*b[i].mass;py+=b[i].vy*b[i].mass;pz+=b[i].vz*b[i].mass;}
    b[0].vx=-px/solar_mass;b[0].vy=-py/solar_mass;b[0].vz=-pz/solar_mass;
    double initial=energy(b);
    for(int64_t step=0;step<input[0];step++){
        for(size_t i=0;i<5;i++)for(size_t j=i+1;j<5;j++){
            double dx=b[i].x-b[j].x,dy=b[i].y-b[j].y,dz=b[i].z-b[j].z;
            double distance=sqrt(dx*dx+dy*dy+dz*dz),mag=0.01/(distance*distance*distance);
            b[i].vx-=dx*b[j].mass*mag;b[i].vy-=dy*b[j].mass*mag;b[i].vz-=dz*b[j].mass*mag;
            b[j].vx+=dx*b[i].mass*mag;b[j].vy+=dy*b[i].mass*mag;b[j].vz+=dz*b[i].mass*mag;
        }
        for(size_t i=0;i<5;i++){b[i].x+=0.01*b[i].vx;b[i].y+=0.01*b[i].vy;b[i].z+=0.01*b[i].vz;}
    }
    double final=energy(b);put_f64(output,0,initial);put_f64(output,8,final);return 16;
}
