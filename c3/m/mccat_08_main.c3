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
module mccat_08_main;
import "core:math";

const long HEADER=20, MAX_POINTS=16, MAX_INPUT=68, MAX_FRAMES=360;
const double MICRO=1000000.0, SOURCE_PI=3.14159265359;
struct Matrix { double v[4][4]; }

fn Matrix identity(){Matrix m;for(int r=0;r<4;r++)for(int c=0;c<4;c++)m.v[r][c]=r==c?1.0:0.0;return m;}
fn Matrix scale_matrix(double x,double y,double z){Matrix m=identity();m.v[0][0]=x;m.v[1][1]=y;m.v[2][2]=z;return m;}
fn Matrix translate_matrix(double x,double y,double z){Matrix m=identity();m.v[0][3]=x;m.v[1][3]=y;m.v[2][3]=z;return m;}
fn Matrix multiply(Matrix a,Matrix b){Matrix out;for(int r=0;r<4;r++)for(int c=0;c<4;c++){out.v[r][c]=0.0;for(int k=0;k<4;k++)out.v[r][c]+=a.v[r][k]*b.v[k][c];}return out;}
fn Matrix rotate_matrix(double rx,double ry,double rz){
    double dx=SOURCE_PI/180.0*rx,dy=SOURCE_PI/180.0*ry,dz=SOURCE_PI/180.0*rz;
    double cx=math.cos(dx),sx=math.sin(dx),cy=math.cos(dy),sy=math.sin(dy),cz=math.cos(dz),sz=math.sin(dz);
    Matrix x=identity(),y=identity(),z=identity();x.v[1][1]=cx;x.v[1][2]= -sx;x.v[2][1]=sx;x.v[2][2]=cx;
    y.v[0][0]=cy;y.v[0][2]=sy;y.v[2][0]= -sy;y.v[2][2]=cy;z.v[0][0]=cz;z.v[0][1]= -sz;z.v[1][0]=sz;z.v[1][1]=cz;
    return multiply(multiply(x,y),z);
}
fn void apply(Matrix m,double p[3],double out[3]){for(int r=0;r<3;r++)out[r]=p[0]*m.v[r][0]+p[1]*m.v[r][1]+p[2]*m.v[r][2]+m.v[r][3];}
fn long round_milli(double value){double v=value*1000.0;return long(v>=0.0?math.floor(v+0.5):math.ceil(v-0.5));}
fn bool bounded(long value,long limit){return value>=-limit&&value<=limit;}

fn long mccat_08_main(long* input,usz length) @export("mccat_08_main") {
    if(input==null||length<HEADER||length>MAX_INPUT)return -1;
    long frames64=input[0],count64=input[1];if(frames64<1||frames64>MAX_FRAMES||count64<1||count64>MAX_POINTS)return -1;
    int frames=int(frames64),count=int(count64);if(length!=usz(HEADER+3*count))return -1;
    for(int i=2;i<5;i++)if(!bounded(input[i],4000000))return -1;for(int i=11;i<14;i++)if(!bounded(input[i],4000000))return -1;
    for(int i=5;i<8;i++)if(!bounded(input[i],360000000))return -1;for(int i=14;i<17;i++)if(!bounded(input[i],360000000))return -1;
    for(int i=8;i<11;i++)if(!bounded(input[i],100000000))return -1;for(int i=17;i<20;i++)if(!bounded(input[i],100000000))return -1;
    double points[MAX_POINTS][3];long raw[MAX_POINTS][3];int unique=0;
    for(int point=0;point<count;point++){
        long p[3]={input[HEADER+3*point],input[HEADER+3*point+1],input[HEADER+3*point+2]};for(int axis=0;axis<3;axis++)if(!bounded(p[axis],100000000))return -1;
        bool duplicate=false;for(int prior=0;prior<unique;prior++)if(raw[prior][0]==p[0]&&raw[prior][1]==p[1]&&raw[prior][2]==p[2])duplicate=true;
        if(!duplicate){for(int axis=0;axis<3;axis++){raw[unique][axis]=p[axis];points[unique][axis]=double(p[axis])/MICRO;}unique++;}
    }
    long checksum=0;
    for(int frame=0;frame<frames;frame++){
        Matrix cs=scale_matrix(double(input[2])/MICRO,double(input[3])/MICRO,double(input[4])/MICRO);
        Matrix cr=rotate_matrix(double(input[5])/MICRO,double(input[6])/MICRO,double(input[7])/MICRO);
        Matrix ct=translate_matrix(double(input[8])/MICRO,double(input[9])/MICRO,double(input[10])/MICRO);
        Matrix ps=scale_matrix(double(input[11])/MICRO,double(input[12])/MICRO,double(input[13])/MICRO);
        Matrix pr=rotate_matrix(double(input[14])/MICRO,double(input[15])/MICRO+double(frame),double(input[16])/MICRO);
        Matrix pt=translate_matrix(double(input[17])/MICRO,double(input[18])/MICRO,double(input[19])/MICRO);
        for(int point=0;point<unique;point++){
            double a[3],b[3],c[3],d[3],e[3],f[3];apply(cs,points[point],a);apply(cr,a,b);apply(ct,b,c);apply(ps,c,d);apply(pr,d,e);apply(pt,e,f);
            long weight=long(frame+1)*long(point+1);checksum+=weight*(round_milli(f[0])+3*round_milli(f[1])+7*round_milli(f[2]));
        }
    }
    return checksum;
}
