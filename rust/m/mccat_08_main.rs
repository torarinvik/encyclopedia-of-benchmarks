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
const MAX_POINTS: usize = 16;
const HEADER: usize = 20;
const MAX_INPUT: usize = 68;
const MICRO: f64 = 1_000_000.0;
const PI_SOURCE: f64 = 3.14159265359;

type Matrix = [[f64; 4]; 4];
fn identity() -> Matrix {
    let mut m = [[0.0; 4]; 4];
    for r in 0..4 { for c in 0..4 { m[r][c] = if r == c { 1.0 } else { 0.0 }; } }
    m
}
fn scale_matrix(x: f64, y: f64, z: f64) -> Matrix { let mut m=identity();m[0][0]=x;m[1][1]=y;m[2][2]=z;m }
fn translate_matrix(x: f64, y: f64, z: f64) -> Matrix { let mut m=identity();m[0][3]=x;m[1][3]=y;m[2][3]=z;m }
fn multiply(a: &Matrix, b: &Matrix) -> Matrix {
    let mut out=[[0.0;4];4];
    for r in 0..4 { for c in 0..4 { for k in 0..4 { out[r][c]+=a[r][k]*b[k][c]; } } }
    out
}
fn rotate_matrix(rx:f64,ry:f64,rz:f64)->Matrix {
    let dx=PI_SOURCE/180.0*rx;let dy=PI_SOURCE/180.0*ry;let dz=PI_SOURCE/180.0*rz;
    let (cx,sx)=(dx.cos(),dx.sin());let (cy,sy)=(dy.cos(),dy.sin());let (cz,sz)=(dz.cos(),dz.sin());
    let mut x=identity();let mut y=identity();let mut z=identity();
    x[1][1]=cx;x[1][2]= -sx;x[2][1]=sx;x[2][2]=cx;
    y[0][0]=cy;y[0][2]=sy;y[2][0]= -sy;y[2][2]=cy;
    z[0][0]=cz;z[0][1]= -sz;z[1][0]=sz;z[1][1]=cz;
    let xy=multiply(&x,&y);multiply(&xy,&z)
}
fn apply(m:&Matrix,p:[f64;3])->[f64;3] {
    let mut out=[0.0;3];for r in 0..3 { out[r]=p[0]*m[r][0]+p[1]*m[r][1]+p[2]*m[r][2]+m[r][3]; }out
}
fn round_milli(value:f64)->i64 {let v=value*1000.0;if v>=0.0{(v+0.5).floor() as i64}else{(v-0.5).ceil() as i64}}
fn bounded(value:i64,limit:i64)->bool {value>=-limit&&value<=limit}

#[no_mangle]
pub unsafe extern "C" fn mccat_08_main(input:*const i64,length:usize)->i64 {
    if input.is_null()||length<HEADER||length>MAX_INPUT{return -1;}
    let values=unsafe{std::slice::from_raw_parts(input,length)};
    if !(1..=360).contains(&values[0])||!(1..=MAX_POINTS as i64).contains(&values[1]){return -1;}
    let frames=values[0] as usize;let count=values[1] as usize;if length!=HEADER+3*count{return -1;}
    for i in 2..5 {if !bounded(values[i],4_000_000){return -1;}}
    for i in 11..14 {if !bounded(values[i],4_000_000){return -1;}}
    for i in 5..8 {if !bounded(values[i],360_000_000){return -1;}}
    for i in 14..17 {if !bounded(values[i],360_000_000){return -1;}}
    for i in 8..11 {if !bounded(values[i],100_000_000){return -1;}}
    for i in 17..20 {if !bounded(values[i],100_000_000){return -1;}}
    let mut points=[[0.0;3];MAX_POINTS];let mut raw=[[0i64;3];MAX_POINTS];let mut unique=0usize;
    for i in 0..count {let p=[values[HEADER+3*i],values[HEADER+3*i+1],values[HEADER+3*i+2]];if p.iter().any(|&v|!bounded(v,100_000_000)){return -1;}let duplicate=(0..unique).any(|j|raw[j]==p);if !duplicate{raw[unique]=p;for axis in 0..3{points[unique][axis]=p[axis] as f64/MICRO;}unique+=1;}}
    let mut checksum=0i64;
    for frame in 0..frames {
        let child_scale=scale_matrix(values[2] as f64/MICRO,values[3] as f64/MICRO,values[4] as f64/MICRO);
        let child_rotation=rotate_matrix(values[5] as f64/MICRO,values[6] as f64/MICRO,values[7] as f64/MICRO);
        let child_translation=translate_matrix(values[8] as f64/MICRO,values[9] as f64/MICRO,values[10] as f64/MICRO);
        let parent_scale=scale_matrix(values[11] as f64/MICRO,values[12] as f64/MICRO,values[13] as f64/MICRO);
        let parent_rotation=rotate_matrix(values[14] as f64/MICRO,values[15] as f64/MICRO+frame as f64,values[16] as f64/MICRO);
        let parent_translation=translate_matrix(values[17] as f64/MICRO,values[18] as f64/MICRO,values[19] as f64/MICRO);
        for point in 0..unique {let a=apply(&child_scale,points[point]);let b=apply(&child_rotation,a);let c=apply(&child_translation,b);let d=apply(&parent_scale,c);let e=apply(&parent_rotation,d);let f=apply(&parent_translation,e);let weight=(frame as i64+1)*(point as i64+1);checksum+=weight*(round_milli(f[0])+3*round_milli(f[1])+7*round_milli(f[2]));}
    }
    checksum
}
