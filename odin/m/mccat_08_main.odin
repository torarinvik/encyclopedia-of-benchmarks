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
package mccat_08_main

import "core:c"
import "core:math"

HEADER :: 20
MAX_POINTS :: 16
MAX_INPUT :: 68
MAX_FRAMES :: 360
MICRO :: 1000000.0
SOURCE_PI :: 3.14159265359
Matrix :: [4][4]f64

identity :: proc "contextless" () -> Matrix {
    m: Matrix
    for r:=0;r<4;r+=1 {for c0:=0;c0<4;c0+=1{m[r][c0]=if r==c0{1.0}else{0.0}}}
    return m
}
scale_matrix :: proc "contextless" (x,y,z:f64)->Matrix {m:=identity();m[0][0]=x;m[1][1]=y;m[2][2]=z;return m}
translate_matrix :: proc "contextless" (x,y,z:f64)->Matrix {m:=identity();m[0][3]=x;m[1][3]=y;m[2][3]=z;return m}
multiply :: proc "contextless" (a,b:Matrix)->Matrix {out:Matrix;for r:=0;r<4;r+=1{for c0:=0;c0<4;c0+=1{for k:=0;k<4;k+=1{out[r][c0]+=a[r][k]*b[k][c0]}}};return out}
rotate_matrix :: proc "contextless" (rx,ry,rz:f64)->Matrix {
    dx:=SOURCE_PI/180.0*rx;dy:=SOURCE_PI/180.0*ry;dz:=SOURCE_PI/180.0*rz
    cx:=math.cos(dx);sx:=math.sin(dx);cy:=math.cos(dy);sy:=math.sin(dy);cz:=math.cos(dz);sz:=math.sin(dz)
    x:=identity();y:=identity();z:=identity()
    x[1][1]=cx;x[1][2]= -sx;x[2][1]=sx;x[2][2]=cx
    y[0][0]=cy;y[0][2]=sy;y[2][0]= -sy;y[2][2]=cy
    z[0][0]=cz;z[0][1]= -sz;z[1][0]=sz;z[1][1]=cz
    return multiply(multiply(x,y),z)
}
apply :: proc "contextless" (m:Matrix,p:[3]f64)->[3]f64 {out:[3]f64;for r:=0;r<3;r+=1{out[r]=p[0]*m[r][0]+p[1]*m[r][1]+p[2]*m[r][2]+m[r][3]};return out}
round_milli :: proc "contextless" (value:f64)->i64 {v:=value*1000.0;if v>=0{return i64(math.floor_f64(v+0.5))};return i64(math.ceil_f64(v-0.5))}
bounded :: proc "contextless" (value,limit:i64)->bool{return value>= -limit&&value<=limit}

@(export)
mccat_08_main :: proc "c" (input:[^]i64,length:c.size_t)->i64 {
    if input==nil||length<HEADER||length>MAX_INPUT do return -1
    frames64,count64:=input[0],input[1];if frames64<1||frames64>MAX_FRAMES||count64<1||count64>MAX_POINTS do return -1
    frames,count:=int(frames64),int(count64);if length!=c.size_t(HEADER+3*count) do return -1
    for i:=2;i<5;i+=1{if !bounded(input[i],4000000) do return -1};for i:=11;i<14;i+=1{if !bounded(input[i],4000000) do return -1}
    for i:=5;i<8;i+=1{if !bounded(input[i],360000000) do return -1};for i:=14;i<17;i+=1{if !bounded(input[i],360000000) do return -1}
    for i:=8;i<11;i+=1{if !bounded(input[i],100000000) do return -1};for i:=17;i<20;i+=1{if !bounded(input[i],100000000) do return -1}
    points:[MAX_POINTS][3]f64;raw:[MAX_POINTS][3]i64;unique:=0
    for point:=0;point<count;point+=1{p:=[3]i64{input[HEADER+3*point],input[HEADER+3*point+1],input[HEADER+3*point+2]};for axis:=0;axis<3;axis+=1{if !bounded(p[axis],100000000) do return -1};duplicate:=false;for prior:=0;prior<unique;prior+=1{if raw[prior][0]==p[0]&&raw[prior][1]==p[1]&&raw[prior][2]==p[2]{duplicate=true}};if !duplicate{raw[unique]=p;for axis:=0;axis<3;axis+=1{points[unique][axis]=f64(p[axis])/MICRO};unique+=1}}
    checksum:=i64(0)
    for frame:=0;frame<frames;frame+=1{
        cs:=scale_matrix(f64(input[2])/MICRO,f64(input[3])/MICRO,f64(input[4])/MICRO);cr:=rotate_matrix(f64(input[5])/MICRO,f64(input[6])/MICRO,f64(input[7])/MICRO);ct:=translate_matrix(f64(input[8])/MICRO,f64(input[9])/MICRO,f64(input[10])/MICRO)
        ps:=scale_matrix(f64(input[11])/MICRO,f64(input[12])/MICRO,f64(input[13])/MICRO);pr:=rotate_matrix(f64(input[14])/MICRO,f64(input[15])/MICRO+f64(frame),f64(input[16])/MICRO);pt:=translate_matrix(f64(input[17])/MICRO,f64(input[18])/MICRO,f64(input[19])/MICRO)
        for point:=0;point<unique;point+=1{a:=apply(cs,points[point]);b:=apply(cr,a);c0:=apply(ct,b);d:=apply(ps,c0);e:=apply(pr,d);f:=apply(pt,e);weight:=i64(frame+1)*i64(point+1);checksum+=weight*(round_milli(f[0])+3*round_milli(f[1])+7*round_milli(f[2]))}
    }
    return checksum
}
