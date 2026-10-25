/****
    Copyright (C) 1996 McGill University.
    Copyright (C) 1996 McCAT System Group.
    Copyright (C) 1996 ACAPS Benchmark Administrator
                       benadmin@acaps.cs.mcgill.ca

    This program is free software; you can redistribute it and/or modify
    it provided this copyright notice is maintained.
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
****/
#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxPoints=16,kHeader=20,kMaxInput=68,kMaxFrames=360;
constexpr std::int64_t kCoordLimit=100000000,kScaleLimit=4000000,kAngleLimit=360000000;
constexpr double kMicro=1000000.0,kPi=3.14159265359;
struct Matrix { double v[4][4]{}; };
void identity(Matrix& m){for(int r=0;r<4;++r)for(int c=0;c<4;++c)m.v[r][c]=r==c?1.0:0.0;}
Matrix scale_matrix(double x,double y,double z){Matrix m;identity(m);m.v[0][0]=x;m.v[1][1]=y;m.v[2][2]=z;return m;}
Matrix translate_matrix(double x,double y,double z){Matrix m;identity(m);m.v[0][3]=x;m.v[1][3]=y;m.v[2][3]=z;return m;}
Matrix multiply(const Matrix& a,const Matrix& b){Matrix out;for(int r=0;r<4;++r)for(int c=0;c<4;++c){out.v[r][c]=0;for(int k=0;k<4;++k)out.v[r][c]+=a.v[r][k]*b.v[k][c];}return out;}
Matrix rotate_matrix(double rx,double ry,double rz){
    const double dx=kPi/180.0*rx,dy=kPi/180.0*ry,dz=kPi/180.0*rz;
    const double cx=std::cos(dx),sx=std::sin(dx),cy=std::cos(dy),sy=std::sin(dy),cz=std::cos(dz),sz=std::sin(dz);
    Matrix x,y,z;identity(x);identity(y);identity(z);
    x.v[1][1]=cx;x.v[1][2]=-sx;x.v[2][1]=sx;x.v[2][2]=cx;
    y.v[0][0]=cy;y.v[0][2]=sy;y.v[2][0]=-sy;y.v[2][2]=cy;
    z.v[0][0]=cz;z.v[0][1]=-sz;z.v[1][0]=sz;z.v[1][1]=cz;
    return multiply(multiply(x,y),z);
}
void apply(const Matrix& m,const double p[3],double out[3]){for(int r=0;r<3;++r)out[r]=p[0]*m.v[r][0]+p[1]*m.v[r][1]+p[2]*m.v[r][2]+m.v[r][3];}
std::int64_t round_milli(double value){double v=value*1000.0;return static_cast<std::int64_t>(v>=0?std::floor(v+0.5):std::ceil(v-0.5));}
bool bounded(std::int64_t x,std::int64_t limit){return x>=-limit&&x<=limit;}
}

extern "C" std::int64_t mccat_08_main(const std::int64_t* input,std::size_t length){
    if(!input||length<kHeader||length>kMaxInput)return -1;
    if(input[0]<1||input[0]>kMaxFrames||input[1]<1||input[1]>kMaxPoints)return -1;
    const int frames=static_cast<int>(input[0]),count=static_cast<int>(input[1]);if(length!=static_cast<std::size_t>(kHeader+3*count))return -1;
    for(int i=2;i<5;++i)if(!bounded(input[i],kScaleLimit))return -1;
    for(int i=11;i<14;++i)if(!bounded(input[i],kScaleLimit))return -1;
    for(int i=5;i<8;++i)if(!bounded(input[i],kAngleLimit))return -1;
    for(int i=14;i<17;++i)if(!bounded(input[i],kAngleLimit))return -1;
    for(int i=8;i<11;++i)if(!bounded(input[i],kCoordLimit))return -1;
    for(int i=17;i<20;++i)if(!bounded(input[i],kCoordLimit))return -1;
    double points[kMaxPoints][3]{};std::int64_t raw[kMaxPoints][3]{};int unique=0;
    for(int i=0;i<count;++i){std::int64_t p[3];for(int a=0;a<3;++a){p[a]=input[kHeader+3*i+a];if(!bounded(p[a],kCoordLimit))return -1;}bool dup=false;for(int j=0;j<unique;++j)if(raw[j][0]==p[0]&&raw[j][1]==p[1]&&raw[j][2]==p[2])dup=true;if(!dup){for(int a=0;a<3;++a){raw[unique][a]=p[a];points[unique][a]=static_cast<double>(p[a])/kMicro;}++unique;}}
    std::int64_t checksum=0;
    for(int frame=0;frame<frames;++frame){
        Matrix cs=scale_matrix(double(input[2])/kMicro,double(input[3])/kMicro,double(input[4])/kMicro);
        Matrix cr=rotate_matrix(double(input[5])/kMicro,double(input[6])/kMicro,double(input[7])/kMicro);
        Matrix ct=translate_matrix(double(input[8])/kMicro,double(input[9])/kMicro,double(input[10])/kMicro);
        Matrix ps=scale_matrix(double(input[11])/kMicro,double(input[12])/kMicro,double(input[13])/kMicro);
        Matrix pr=rotate_matrix(double(input[14])/kMicro,double(input[15])/kMicro+double(frame),double(input[16])/kMicro);
        Matrix pt=translate_matrix(double(input[17])/kMicro,double(input[18])/kMicro,double(input[19])/kMicro);
        for(int point=0;point<unique;++point){double a[3],b[3],c[3],d[3],e[3],f[3];apply(cs,points[point],a);apply(cr,a,b);apply(ct,b,c);apply(ps,c,d);apply(pr,d,e);apply(pt,e,f);const std::int64_t weight=std::int64_t(frame+1)*(point+1);checksum+=weight*(round_milli(f[0])+3*round_milli(f[1])+7*round_milli(f[2]));}
    }
    return checksum;
}
