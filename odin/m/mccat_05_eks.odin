/*
    Copyright (C) 1996 McGill University.
    Copyright (C) 1996 McCAT System Group.
    Copyright (C) 1996 ACAPS Benchmark Administrator
                       benadmin@acaps.cs.mcgill.ca

    This program is free software; you can redistribute it and/or modify
    it provided this copyright notice is maintained.
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*/
package mccat_05_eks

import "core:c"
import "core:math"

MIN_N :: 3
MAX_N :: 8
MAX_INPUT :: 66
INPUT_SCALE :: 1000000.0
OUTPUT_SCALE :: 1000.0
QR_EPSILON :: 1.0e-10
MAX_QR_STEPS :: 4096

absd :: proc "contextless" (value: f64) -> f64 {
    if value < 0.0 do return -value
    return value
}
givens :: proc "contextless" (a, b: f64) -> (s, c: f64) {
    if b == 0.0 do return 0.0, 1.0
    if absd(b) > absd(a) { t := -a/b; s = 1.0/math.sqrt_f64(1.0+t*t); c=s*t }
    else { t := -b/a; c=1.0/math.sqrt_f64(1.0+t*t); s=c*t }
    return s, c
}
apply_givens :: proc "contextless" (a: [^]f64, n: int, s, c: f64, i, j, start, ending: int) {
    for k := start; k <= ending; k += 1 { x:=a[i*n+k];y:=a[j*n+k];a[i*n+k]=c*x-s*y;a[j*n+k]=s*x+c*y }
    for k := start; k <= ending; k += 1 { x:=a[k*n+i];y:=a[k*n+j];a[k*n+i]=c*x-s*y;a[k*n+j]=s*x+c*y }
}
reduce_band :: proc "contextless" (a: [^]f64, n, bandwidth: int) {
    for i:=bandwidth;i>=2;i-=1 { for j:=0;j<n-i;j+=1 {
        s,c:=givens(a[j*n+j+i-1],a[j*n+j+i]);ending:=j+2*i;if ending>=n{ending=n-1};apply_givens(a,n,s,c,j+i-1,j+i,j,ending)
        for m:=j+i;m<n-i;m+=i { s,c= givens(a[(m-1)*n+m+i-1],a[(m-1)*n+m+i]);ending=m+2*i;if ending>=n{ending=n-1};apply_givens(a,n,s,c,m+i-1,m+i,m-1,ending) }
    } }
}
qr_iterate :: proc "contextless" (a: [^]f64, n: int) -> bool {
    steps:=0
    for {
        for i:=0;i<n-1;i+=1 { if absd(a[(i+1)*n+i])<(absd(a[i*n+i])+absd(a[(i+1)*n+i+1]))*QR_EPSILON {a[(i+1)*n+i]=0;a[i*n+i+1]=0} }
        q:=n-1;for q>0&&a[(q-1)*n+q]==0 {q-=1};if q==0{return true};steps+=1;if steps>MAX_QR_STEPS{return false}
        p:=q;for p>0&&a[(p-1)*n+p]!=0 {p-=1}
        d:=(a[(q-1)*n+q-1]-a[q*n+q])/2.0;t:=a[q*n+q-1]*a[q*n+q-1];sign:=f64(1);if d<0{sign= -1}
        mu:=a[q*n+q]-t/(d+sign*math.sqrt_f64(d*d+t));x:=a[p*n+p]-mu;z:=a[(p+1)*n+p]
        for i:=p;i<q;i+=1 {s,c:=givens(x,z);l:=p;if i-1>p{l=i-1};m:=i+2;if m>q{m=q}
            for k:=l;k<=m;k+=1{u:=a[i*n+k];v:=a[(i+1)*n+k];a[i*n+k]=c*u-s*v;a[(i+1)*n+k]=s*u+c*v}
            for k:=l;k<=m;k+=1{u:=a[k*n+i];v:=a[k*n+i+1];a[k*n+i]=c*u-s*v;a[k*n+i+1]=s*u+c*v}
            if i<q-1{x=a[(i+1)*n+i];z=a[(i+2)*n+i]}
        }
    }
}
project :: proc "contextless" (value:f64)->i32 {scaled:=value*OUTPUT_SCALE;if scaled>=0{return i32(math.floor_f64(scaled+0.5))};return i32(math.ceil_f64(scaled-0.5))}
before :: proc "contextless" (left,right:f64)->bool{return absd(left)>absd(right)||(absd(left)==absd(right)&&left<right)}
put_i32_le :: proc "contextless" (output:[^]u8,offset:int,value:i32){bits:=transmute(u32)value;for i:=0;i<4;i+=1{output[offset+i]=u8(bits>>u32(8*i))}}

@(export)
mccat_05_eks :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
    if input==nil||length<2||length>MAX_INPUT do return -1
    n64:=input[0];bw64:=input[1];if n64<MIN_N||n64>MAX_N||bw64<2||bw64>5||bw64>=n64 do return -1
    n:=int(n64);bandwidth:=int(bw64);if length!=c.size_t(2+n*n) do return -1
    a:[64]f64
    for row:=0;row<n;row+=1 {for column:=0;column<n;column+=1 {value:=input[2+row*n+column];if value< -1000000||value>1000000 do return -1;if row>column&&value!=input[2+column*n+row] do return -1;distance:=row-column;if distance<0{distance= -distance};if distance>bandwidth&&value!=0 do return -1;a[row*n+column]=f64(value)/INPUT_SCALE}}
    required:=c.size_t(n*4);if output==nil||capacity<required do return -2
    reduce_band(&a[0],n,bandwidth);if !qr_iterate(&a[0],n) do return -1
    eigenvalues:[MAX_N]f64;for i:=0;i<n;i+=1{eigenvalues[i]=a[i*n+i]}
    for i:=1;i<n;i+=1{value:=eigenvalues[i];j:=i;for j>0&&before(value,eigenvalues[j-1]){eigenvalues[j]=eigenvalues[j-1];j-=1};eigenvalues[j]=value}
    staged:[MAX_N*4]u8;for i:=0;i<n;i+=1{put_i32_le(&staged[0],4*i,project(eigenvalues[i]))}
    for i:=0;i<int(required);i+=1{output[i]=staged[i]};return i64(required)
}
