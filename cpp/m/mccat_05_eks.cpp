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
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMinN = 3, kMaxN = 8, kMaxInput = 2 + kMaxN * kMaxN;
constexpr int kMaxOutput = kMaxN * 4;
constexpr double kInputScale = 1000000.0, kOutputScale = 1000.0;
constexpr double kQrEpsilon = 1.0e-10;
constexpr int kMaxQrSteps = 4096;
double absd(double x) { return x < 0.0 ? -x : x; }
void givens(double a, double b, double& s, double& c) {
    double t;
    if (b == 0.0) { c = 1.0; s = 0.0; }
    else if (absd(b) > absd(a)) { t = -a / b; s = 1.0 / std::sqrt(1.0 + t*t); c = s*t; }
    else { t = -b / a; c = 1.0 / std::sqrt(1.0 + t*t); s = c*t; }
}
void apply_givens(double* a, int n, double s, double c, int i, int j, int start, int end) {
    for (int k = start; k <= end; ++k) { double x=a[i*n+k], y=a[j*n+k]; a[i*n+k]=c*x-s*y; a[j*n+k]=s*x+c*y; }
    for (int k = start; k <= end; ++k) { double x=a[k*n+i], y=a[k*n+j]; a[k*n+i]=c*x-s*y; a[k*n+j]=s*x+c*y; }
}
void reduce_band(double* a, int n, int bw) {
    for (int i=bw; i>=2; --i) for (int j=0; j<n-i; ++j) {
        double s,c; givens(a[j*n+j+i-1],a[j*n+j+i],s,c);
        int end=j+2*i<n?j+2*i:n-1; apply_givens(a,n,s,c,j+i-1,j+i,j,end);
        for (int m=j+i; m<n-i; m+=i) {
            givens(a[(m-1)*n+m+i-1],a[(m-1)*n+m+i],s,c);
            end=m+2*i<n?m+2*i:n-1; apply_givens(a,n,s,c,m+i-1,m+i,m-1,end);
        }
    }
}
bool qr_iterate(double* a, int n) {
    int steps=0;
    for (;;) {
        for(int i=0;i<n-1;++i) if(absd(a[(i+1)*n+i])<(absd(a[i*n+i])+absd(a[(i+1)*n+i+1]))*kQrEpsilon) a[(i+1)*n+i]=a[i*n+i+1]=0.0;
        int q=n-1; while(q>0&&a[(q-1)*n+q]==0.0)--q; if(q==0)return true;
        if(++steps>kMaxQrSteps)return false;
        int p=q; while(p>0&&a[(p-1)*n+p]!=0.0)--p;
        double d=(a[(q-1)*n+q-1]-a[q*n+q])/2.0, t=a[q*n+q-1]*a[q*n+q-1];
        double mu=a[q*n+q]-t/(d+(d<0.0?-1.0:1.0)*std::sqrt(d*d+t));
        double x=a[p*n+p]-mu, z=a[(p+1)*n+p];
        for(int i=p;i<q;++i){double s,c;givens(x,z,s,c);int l=i-1>p?i-1:p,m=q<i+2?q:i+2;
            for(int k=l;k<=m;++k){double u=a[i*n+k],v=a[(i+1)*n+k];a[i*n+k]=c*u-s*v;a[(i+1)*n+k]=s*u+c*v;}
            for(int k=l;k<=m;++k){double u=a[k*n+i],v=a[k*n+i+1];a[k*n+i]=c*u-s*v;a[k*n+i+1]=s*u+c*v;}
            if(i<q-1){x=a[(i+1)*n+i];z=a[(i+2)*n+i];}
        }
    }
}
std::int32_t project(double x) { double y=x*kOutputScale; return static_cast<std::int32_t>(y>=0.0?std::floor(y+0.5):std::ceil(y-0.5)); }
bool before(double x,double y){double ax=absd(x),ay=absd(y);return ax>ay||(ax==ay&&x<y);}
void put_i32(std::int32_t value,std::uint8_t* out){std::uint32_t bits=static_cast<std::uint32_t>(value);for(int i=0;i<4;++i)out[i]=static_cast<std::uint8_t>(bits>>(8*i));}
}

extern "C" std::int64_t mccat_05_eks(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t capacity){
    if(!input||length<2||length>kMaxInput)return -1;
    std::int64_t n64=input[0],bw64=input[1];if(n64<kMinN||n64>kMaxN||bw64<2||bw64>5||bw64>=n64)return -1;
    int n=static_cast<int>(n64),bw=static_cast<int>(bw64);if(length!=static_cast<std::size_t>(2+n*n))return -1;
    double a[kMaxN*kMaxN]={};
    for(int r=0;r<n;++r)for(int c=0;c<n;++c){std::int64_t v=input[2+r*n+c];if(v< -1000000||v>1000000)return -1;if(r>c&&v!=input[2+c*n+r])return -1;if((r>c?r-c:c-r)>bw&&v!=0)return -1;a[r*n+c]=static_cast<double>(v)/kInputScale;}
    std::size_t required=static_cast<std::size_t>(n)*4;if(!output||capacity<required)return -2;
    reduce_band(a,n,bw);if(!qr_iterate(a,n))return -1;
    double values[kMaxN];for(int i=0;i<n;++i)values[i]=a[i*n+i];
    for(int i=1;i<n;++i){double v=values[i];int j=i;while(j>0&&before(v,values[j-1])){values[j]=values[j-1];--j;}values[j]=v;}
    std::uint8_t staged[kMaxOutput];for(int i=0;i<n;++i)put_i32(project(values[i]),staged+4*i);
    for(std::size_t i=0;i<required;++i)output[i]=staged[i];return static_cast<std::int64_t>(required);
}
