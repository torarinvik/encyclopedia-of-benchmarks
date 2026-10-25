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
module mccat_05_eks;
import "core:math";

const long MIN_N = 3, MAX_N = 8, MAX_INPUT = 66;
const double INPUT_SCALE = 1000000.0, OUTPUT_SCALE = 1000.0, QR_EPSILON = 1.0e-10;
const int MAX_QR_STEPS = 4096;
struct Rotation { double s; double c; }

fn double absd(double x) { return x < 0.0 ? -x : x; }
fn Rotation givens(double a, double b) {
    if (b == 0.0) return Rotation{0.0, 1.0};
    if (absd(b) > absd(a)) { t := -a / b; s := 1.0 / math.sqrt(1.0 + t * t); return Rotation{s, s * t}; }
    t := -b / a; c := 1.0 / math.sqrt(1.0 + t * t); return Rotation{c * t, c};
}
fn void apply_givens(double* a, int n, double s, double c, int i, int j, int start, int end) {
    for (int k = start; k <= end; k++) { x := a[i*n+k]; y := a[j*n+k]; a[i*n+k] = c*x-s*y; a[j*n+k] = s*x+c*y; }
    for (int k = start; k <= end; k++) { x := a[k*n+i]; y := a[k*n+j]; a[k*n+i] = c*x-s*y; a[k*n+j] = s*x+c*y; }
}
fn void reduce_band(double* a, int n, int bw) {
    for (int i = bw; i >= 2; i--) for (int j = 0; j < n-i; j++) {
        r := givens(a[j*n+j+i-1], a[j*n+j+i]); end := j+2*i<n ? j+2*i : n-1;
        apply_givens(a,n,r.s,r.c,j+i-1,j+i,j,end);
        m := j+i;
        while (m < n-i) { r = givens(a[(m-1)*n+m+i-1],a[(m-1)*n+m+i]); end = m+2*i<n ? m+2*i : n-1;
            apply_givens(a,n,r.s,r.c,m+i-1,m+i,m-1,end); m += i;
        }
    }
}
fn bool qr_iterate(double* a, int n) {
    steps := 0;
    while (true) {
        for (int i=0;i<n-1;i++) if (absd(a[(i+1)*n+i]) < (absd(a[i*n+i])+absd(a[(i+1)*n+i+1]))*QR_EPSILON) { a[(i+1)*n+i]=0.0; a[i*n+i+1]=0.0; }
        q := n-1; while(q>0&&a[(q-1)*n+q]==0.0) q--;
        if(q==0) return true; steps++; if(steps>MAX_QR_STEPS)return false;
        p:=q;while(p>0&&a[(p-1)*n+p]!=0.0)p--;
        d:=(a[(q-1)*n+q-1]-a[q*n+q])/2.0;t:=a[q*n+q-1]*a[q*n+q-1];sign:=d<0.0?-1.0:1.0;
        mu:=a[q*n+q]-t/(d+sign*math.sqrt(d*d+t));x:=a[p*n+p]-mu;z:=a[(p+1)*n+p];
        for(int i=p;i<q;i++){
            r:=givens(x,z);l:=i-1>p?i-1:p;m:=q<i+2?q:i+2;
            for(int k=l;k<=m;k++){u:=a[i*n+k];v:=a[(i+1)*n+k];a[i*n+k]=r.c*u-r.s*v;a[(i+1)*n+k]=r.s*u+r.c*v;}
            for(int k=l;k<=m;k++){u:=a[k*n+i];v:=a[k*n+i+1];a[k*n+i]=r.c*u-r.s*v;a[k*n+i+1]=r.s*u+r.c*v;}
            if(i<q-1){x=a[(i+1)*n+i];z=a[(i+2)*n+i];}
        }
    }
}
fn long project(double value) { scaled:=value*OUTPUT_SCALE;return long(scaled>=0.0?math.floor(scaled+0.5):math.ceil(scaled-0.5)); }
fn bool before(double a,double b){aa:=absd(a);ab:=absd(b);return aa>ab||(aa==ab&&a<b);}
fn void put_i32(long value,uchar* output){bits:=u32(value);output[0]=uchar(bits&255);output[1]=uchar((bits>>8)&255);output[2]=uchar((bits>>16)&255);output[3]=uchar((bits>>24)&255);}

fn long mccat_05_eks(long* input, usz length, uchar* output, usz capacity) @export("mccat_05_eks") {
    if(input==null||length<2||length>MAX_INPUT)return -1;
    n64:=input[0];bw64:=input[1];if(n64<MIN_N||n64>MAX_N||bw64<2||bw64>5||bw64>=n64)return -1;
    n:=int(n64);bw:=int(bw64);if(length!=usz(2+n*n))return -1;
    double a[64]={0.0};
    for(int r=0;r<n;r++)for(int c=0;c<n;c++){
        value:=input[2+r*n+c];if(value< -1000000||value>1000000)return -1;
        if(r>c&&value!=input[2+c*n+r])return -1;
        distance:=r>c?r-c:c-r;if(distance>bw&&value!=0)return -1;
        a[r*n+c]=double(value)/INPUT_SCALE;
    }
    required:=usz(n*4);if(output==null||capacity<required)return -2;
    reduce_band(a,n,bw);if(!qr_iterate(a,n))return -1;
    double values[8]={0.0};for(int i=0;i<n;i++)values[i]=a[i*n+i];
    for(int i=1;i<n;i++){value:=values[i];j:=i;while(j>0&&before(value,values[j-1])){values[j]=values[j-1];j--;}values[j]=value;}
    uchar staged[32]={0};for(int i=0;i<n;i++)put_i32(project(values[i]),staged+4*i);
    for(usz i=0;i<required;i++)output[i]=staged[i];return long(required);
}
