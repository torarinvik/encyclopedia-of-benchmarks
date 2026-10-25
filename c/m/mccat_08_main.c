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
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MIN_POINTS 1
#define MAX_POINTS 16
#define HEADER_WORDS 20
#define MAX_INPUT (HEADER_WORDS + 3 * MAX_POINTS)
#define MICRO 1000000.0
#define COORD_LIMIT 100000000LL
#define SCALE_LIMIT 4000000LL
#define ANGLE_LIMIT 360000000LL
#define MAX_FRAMES 360
#define PI_SOURCE 3.14159265359

typedef struct { double value[4][4]; } Matrix;

static void identity(Matrix *m) {
    for (int r=0;r<4;++r) for (int c=0;c<4;++c) m->value[r][c]=(r==c)?1.0:0.0;
}
static Matrix scale_matrix(double sx,double sy,double sz) {
    Matrix m;identity(&m);m.value[0][0]=sx;m.value[1][1]=sy;m.value[2][2]=sz;return m;
}
static Matrix translate_matrix(double dx,double dy,double dz) {
    Matrix m;identity(&m);m.value[0][3]=dx;m.value[1][3]=dy;m.value[2][3]=dz;return m;
}
static Matrix multiply(const Matrix *a,const Matrix *b) {
    Matrix result;
    for(int r=0;r<4;++r)for(int c=0;c<4;++c){result.value[r][c]=0.0;for(int k=0;k<4;++k)result.value[r][c]+=a->value[r][k]*b->value[k][c];}
    return result;
}
static Matrix rotate_matrix(double rx,double ry,double rz) {
    const double dx=PI_SOURCE/180.0*rx,dy=PI_SOURCE/180.0*ry,dz=PI_SOURCE/180.0*rz;
    const double cx=cos(dx),sx=sin(dx),cy=cos(dy),sy=sin(dy),cz=cos(dz),sz=sin(dz);
    Matrix x,y,z;identity(&x);identity(&y);identity(&z);
    x.value[1][1]=cx;x.value[1][2]=-sx;x.value[2][1]=sx;x.value[2][2]=cx;
    y.value[0][0]=cy;y.value[0][2]=sy;y.value[2][0]=-sy;y.value[2][2]=cy;
    z.value[0][0]=cz;z.value[0][1]=-sz;z.value[1][0]=sz;z.value[1][1]=cz;
    Matrix xy=multiply(&x,&y);return multiply(&xy,&z);
}
static void apply(const Matrix *m,const double p[3],double out[3]) {
    for(int r=0;r<3;++r)out[r]=p[0]*m->value[r][0]+p[1]*m->value[r][1]+p[2]*m->value[r][2]+m->value[r][3];
}
static int64_t round_milli(double value) {
    const double scaled=value*1000.0;
    return (int64_t)(scaled>=0.0?floor(scaled+0.5):ceil(scaled-0.5));
}
static int in_range(int64_t value,int64_t limit) { return value>=-limit&&value<=limit; }

int64_t mccat_08_main(const int64_t *input,size_t length) {
    if(input==NULL||length<HEADER_WORDS||length>MAX_INPUT)return -1;
    const int64_t frame_value=input[0],count_value=input[1];
    if(frame_value<1||frame_value>MAX_FRAMES||count_value<MIN_POINTS||count_value>MAX_POINTS)return -1;
    const int frames=(int)frame_value,count=(int)count_value;
    if(length!=(size_t)(HEADER_WORDS+3*count))return -1;
    for(int i=2;i<5;++i)if(!in_range(input[i],SCALE_LIMIT))return -1;
    for(int i=11;i<14;++i)if(!in_range(input[i],SCALE_LIMIT))return -1;
    for(int i=5;i<8;++i)if(!in_range(input[i],ANGLE_LIMIT))return -1;
    for(int i=14;i<17;++i)if(!in_range(input[i],ANGLE_LIMIT))return -1;
    for(int i=8;i<11;++i)if(!in_range(input[i],COORD_LIMIT))return -1;
    for(int i=17;i<20;++i)if(!in_range(input[i],COORD_LIMIT))return -1;
    double points[MAX_POINTS][3];int64_t raw[MAX_POINTS][3];int unique_count=0;
    for(int i=0;i<count;++i){
        int64_t p[3];for(int axis=0;axis<3;++axis){p[axis]=input[HEADER_WORDS+3*i+axis];if(!in_range(p[axis],COORD_LIMIT))return -1;}
        int duplicate=0;for(int prior=0;prior<unique_count;++prior)if(raw[prior][0]==p[0]&&raw[prior][1]==p[1]&&raw[prior][2]==p[2])duplicate=1;
        if(!duplicate){for(int axis=0;axis<3;++axis){raw[unique_count][axis]=p[axis];points[unique_count][axis]=(double)p[axis]/MICRO;}unique_count++;}
    }
    int64_t checksum=0;
    for(int frame=0;frame<frames;++frame){
        Matrix child_scale=scale_matrix((double)input[2]/MICRO,(double)input[3]/MICRO,(double)input[4]/MICRO);
        Matrix child_rotation=rotate_matrix((double)input[5]/MICRO,(double)input[6]/MICRO,(double)input[7]/MICRO);
        Matrix child_translation=translate_matrix((double)input[8]/MICRO,(double)input[9]/MICRO,(double)input[10]/MICRO);
        Matrix parent_scale=scale_matrix((double)input[11]/MICRO,(double)input[12]/MICRO,(double)input[13]/MICRO);
        Matrix parent_rotation=rotate_matrix((double)input[14]/MICRO,(double)input[15]/MICRO+(double)frame,(double)input[16]/MICRO);
        Matrix parent_translation=translate_matrix((double)input[17]/MICRO,(double)input[18]/MICRO,(double)input[19]/MICRO);
        for(int point=0;point<unique_count;++point){
            double a[3],b[3],c[3],d[3],e[3],f[3];
            apply(&child_scale,points[point],a);apply(&child_rotation,a,b);apply(&child_translation,b,c);
            apply(&parent_scale,c,d);apply(&parent_rotation,d,e);apply(&parent_translation,e,f);
            const int64_t weight=(int64_t)(frame+1)*(point+1);
            checksum+=weight*(round_milli(f[0])+3*round_milli(f[1])+7*round_milli(f[2]));
        }
    }
    return checksum;
}
