#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int Q = 19, Cells = 27, Width = 3, HaloWidth = 5;
constexpr int Dx[Q] = {0,0,0,1,-1,0,0,1,-1,1,-1,0,0,0,0,1,1,-1,-1};
constexpr int Dy[Q] = {0,1,-1,0,0,0,0,1,1,-1,-1,1,1,-1,-1,0,0,0,0};
constexpr int Dz[Q] = {0,0,0,0,0,1,-1,0,0,0,0,1,-1,1,-1,1,-1,1,-1};
constexpr int Opp[Q] = {0,2,1,4,3,6,5,10,9,8,7,14,13,12,11,18,17,16,15};

int cellIndex(int x, int y, int z) { return x + 3*y + 9*z; }
int haloIndex(int x, int y, int z, int q) { return (((z+1)*5+(y+1))*5+(x+1))*Q+q; }
float initialWeight(int q) {
    if (q == 0) return static_cast<float>(1.0 / 3.0);
    if (q <= 6) return static_cast<float>(1.0 / 18.0);
    return static_cast<float>(1.0 / 36.0);
}
float axisFactor(float u, bool positive, float u2) {
    float product = 4.5f*u;
    product = positive ? product+3.0f : product-3.0f;
    product = u*product;
    product = 1.0f+product;
    return product-u2;
}
float diagonalFactor(float cu, float u2) {
    float product=4.5f*cu; product=product+3.0f; product=cu*product; product=1.0f+product; return product-u2;
}
float collide(float source, float rho, float factor, double weight) {
    const float omega=1.95f;
    float base=(1.0f-omega)*source;
    double equilibrium=weight*static_cast<double>(omega);
    equilibrium=equilibrium*static_cast<double>(rho);
    equilibrium=equilibrium*static_cast<double>(factor);
    return static_cast<float>(static_cast<double>(base)+equilibrium);
}
void collideCell(const float *f, float *post) {
    float rho=f[0]; for(int q=1;q<Q;++q) rho=rho+f[q];
    float ux=f[3]; ux=ux-f[4]; ux=ux+f[7]; ux=ux-f[8]; ux=ux+f[9]; ux=ux-f[10]; ux=ux+f[15]; ux=ux+f[16]; ux=ux-f[17]; ux=ux-f[18];
    float uy=f[1]; uy=uy-f[2]; uy=uy+f[7]; uy=uy+f[8]; uy=uy-f[9]; uy=uy-f[10]; uy=uy+f[11]; uy=uy+f[12]; uy=uy-f[13]; uy=uy-f[14];
    float uz=f[5]; uz=uz-f[6]; uz=uz+f[11]; uz=uz-f[12]; uz=uz+f[13]; uz=uz-f[14]; uz=uz+f[15]; uz=uz-f[16]; uz=uz+f[17]; uz=uz-f[18];
    ux=ux/rho; uy=uy/rho; uz=uz/rho;
    float u2=ux*ux; u2=u2+uy*uy; u2=u2+uz*uz; u2=1.5f*u2;
    post[0]=collide(f[0],rho,1.0f-u2,1.0/3.0);
    post[1]=collide(f[1],rho,axisFactor(uy,true,u2),1.0/18.0); post[2]=collide(f[2],rho,axisFactor(uy,false,u2),1.0/18.0);
    post[3]=collide(f[3],rho,axisFactor(ux,true,u2),1.0/18.0); post[4]=collide(f[4],rho,axisFactor(ux,false,u2),1.0/18.0);
    post[5]=collide(f[5],rho,axisFactor(uz,true,u2),1.0/18.0); post[6]=collide(f[6],rho,axisFactor(uz,false,u2),1.0/18.0);
    float cu=ux+uy; post[7]=collide(f[7],rho,diagonalFactor(cu,u2),1.0/36.0);
    cu=-ux+uy; post[8]=collide(f[8],rho,diagonalFactor(cu,u2),1.0/36.0);
    cu=ux-uy; post[9]=collide(f[9],rho,diagonalFactor(cu,u2),1.0/36.0);
    cu=-ux-uy; post[10]=collide(f[10],rho,diagonalFactor(cu,u2),1.0/36.0);
    cu=uy+uz; post[11]=collide(f[11],rho,diagonalFactor(cu,u2),1.0/36.0);
    cu=uy-uz; post[12]=collide(f[12],rho,diagonalFactor(cu,u2),1.0/36.0);
    cu=-uy+uz; post[13]=collide(f[13],rho,diagonalFactor(cu,u2),1.0/36.0);
    cu=-uy-uz; post[14]=collide(f[14],rho,diagonalFactor(cu,u2),1.0/36.0);
    cu=ux+uz; post[15]=collide(f[15],rho,diagonalFactor(cu,u2),1.0/36.0);
    cu=ux-uz; post[16]=collide(f[16],rho,diagonalFactor(cu,u2),1.0/36.0);
    cu=-ux+uz; post[17]=collide(f[17],rho,diagonalFactor(cu,u2),1.0/36.0);
    cu=-ux-uz; post[18]=collide(f[18],rho,diagonalFactor(cu,u2),1.0/36.0);
}
}

extern "C" int64_t parboil_lbm(const int64_t *values, std::size_t length) {
    if (values == nullptr || length != Q) return -1;
    bool nonzero=false;
    for(int q=0;q<Q;++q) { if(values[q]<0||values[q]>100000) return -1; if(values[q]!=0) nonzero=true; }
    if(!nonzero) return -1;
    float source[Cells][Q]{};
    float destination[HaloWidth*HaloWidth*HaloWidth*Q]{};
    for(int z=0;z<Width;++z) for(int y=0;y<Width;++y) for(int x=0;x<Width;++x) {
        const int cell=cellIndex(x,y,z);
        for(int q=0;q<Q;++q) { source[cell][q]=initialWeight(q); destination[haloIndex(x,y,z,q)]=initialWeight(q); }
    }
    for(int q=0;q<Q;++q) source[cellIndex(1,1,1)][q]=static_cast<float>(values[q])/1000000.0f;
    for(int z=0;z<Width;++z) for(int y=0;y<Width;++y) for(int x=0;x<Width;++x) {
        const int cell=cellIndex(x,y,z);
        const bool obstacle=x==0||x==2||y==0||y==2||z==0||z==2;
        float post[Q]{};
        if(!obstacle) collideCell(source[cell],post);
        for(int q=0;q<Q;++q) {
            const float outgoing=obstacle?source[cell][Opp[q]]:post[q];
            destination[haloIndex(x+Dx[q],y+Dy[q],z+Dz[q],q)]=outgoing;
        }
    }
    int64_t checksum=0;
    for(int z=0;z<Width;++z) for(int y=0;y<Width;++y) for(int x=0;x<Width;++x) {
        const int cell=cellIndex(x,y,z);
        for(int q=0;q<Q;++q) checksum+=static_cast<int64_t>(cell+1)*static_cast<int64_t>(std::round(destination[haloIndex(x,y,z,q)]*1000000.0f));
    }
    return checksum;
}
