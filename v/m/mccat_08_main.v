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
module mccat_08_main

import math

const header_words = 20
const max_points = 16
const max_input = 68
const max_frames = 360
const micro = 1_000_000.0
const source_pi = 3.14159265359
type Matrix = [4][4]f64

fn identity() Matrix {
	mut m := Matrix{}
	for r in 0..4 { for c in 0..4 { m[r][c] = if r == c { 1.0 } else { 0.0 } } }
	return m
}
fn scale_matrix(x f64, y f64, z f64) Matrix { mut m:=identity();m[0][0]=x;m[1][1]=y;m[2][2]=z;return m }
fn translate_matrix(x f64, y f64, z f64) Matrix { mut m:=identity();m[0][3]=x;m[1][3]=y;m[2][3]=z;return m }
fn multiply(a Matrix,b Matrix) Matrix { mut out:=Matrix{};for r in 0..4{for c in 0..4{for k in 0..4{out[r][c]+=a[r][k]*b[k][c]}}};return out }
fn rotate_matrix(rx f64,ry f64,rz f64) Matrix {
	dx:=source_pi/180.0*rx;dy:=source_pi/180.0*ry;dz:=source_pi/180.0*rz
	cx:=math.cos(dx);sx:=math.sin(dx);cy:=math.cos(dy);sy:=math.sin(dy);cz:=math.cos(dz);sz:=math.sin(dz)
	mut x:=identity();mut y:=identity();mut z:=identity()
	x[1][1]=cx;x[1][2]= -sx;x[2][1]=sx;x[2][2]=cx
	y[0][0]=cy;y[0][2]=sy;y[2][0]= -sy;y[2][2]=cy
	z[0][0]=cz;z[0][1]= -sz;z[1][0]=sz;z[1][1]=cz
	return multiply(multiply(x,y),z)
}
fn apply(m Matrix,p [3]f64) [3]f64 { mut out:=[3]f64{};for r in 0..3{out[r]=p[0]*m[r][0]+p[1]*m[r][1]+p[2]*m[r][2]+m[r][3]};return out }
fn round_milli(value f64) i64 { v:=value*1000.0;return if v>=0.0{i64(v+0.5)}else{i64(v-0.5)} }
fn bounded(value i64,limit i64) bool {return value>= -limit&&value<=limit}

@[export: 'mccat_08_main']
pub fn mccat_08_main(input &i64,length usize) i64 {
	unsafe {
		if input==nil||length<header_words||length>max_input{return -1}
		frames64:=input[0];count64:=input[1];if frames64<1||frames64>max_frames||count64<1||count64>max_points{return -1}
		frames:=int(frames64);count:=int(count64);if length!=usize(header_words+3*count){return -1}
		for i in 2..5{if !bounded(input[i],4_000_000){return -1}};for i in 11..14{if !bounded(input[i],4_000_000){return -1}}
		for i in 5..8{if !bounded(input[i],360_000_000){return -1}};for i in 14..17{if !bounded(input[i],360_000_000){return -1}}
		for i in 8..11{if !bounded(input[i],100_000_000){return -1}};for i in 17..20{if !bounded(input[i],100_000_000){return -1}}
		mut points:=[max_points][3]f64{};mut raw:=[max_points][3]i64{};mut unique:=0
		for point in 0..count{p:=[3]i64{input[header_words+3*point],input[header_words+3*point+1],input[header_words+3*point+2]};for axis in 0..3{if !bounded(p[axis],100_000_000){return -1}};mut duplicate:=false;for prior in 0..unique{if raw[prior][0]==p[0]&&raw[prior][1]==p[1]&&raw[prior][2]==p[2]{duplicate=true}};if !duplicate{raw[unique]=p;for axis in 0..3{points[unique][axis]=f64(p[axis])/micro};unique++}}
		mut checksum:=i64(0)
		for frame in 0..frames{
			cs:=scale_matrix(f64(input[2])/micro,f64(input[3])/micro,f64(input[4])/micro);cr:=rotate_matrix(f64(input[5])/micro,f64(input[6])/micro,f64(input[7])/micro);ct:=translate_matrix(f64(input[8])/micro,f64(input[9])/micro,f64(input[10])/micro)
			ps:=scale_matrix(f64(input[11])/micro,f64(input[12])/micro,f64(input[13])/micro);pr:=rotate_matrix(f64(input[14])/micro,f64(input[15])/micro+f64(frame),f64(input[16])/micro);pt:=translate_matrix(f64(input[17])/micro,f64(input[18])/micro,f64(input[19])/micro)
			for point in 0..unique{a:=apply(cs,points[point]);b:=apply(cr,a);c:=apply(ct,b);d:=apply(ps,c);e:=apply(pr,d);f:=apply(pt,e);weight:=i64(frame+1)*i64(point+1);checksum+=weight*(round_milli(f[0])+3*round_milli(f[1])+7*round_milli(f[2]))}
		}
		return checksum
	}
}
