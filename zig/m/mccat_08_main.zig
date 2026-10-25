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
const HEADER: usize = 20;
const MAX_POINTS: usize = 16;
const MAX_INPUT: usize = 68;
const MICRO: f64 = 1_000_000.0;
const SOURCE_PI: f64 = 3.14159265359;
const Matrix = [4][4]f64;

fn identity() Matrix {
    var m: Matrix = .{.{0,0,0,0},.{0,0,0,0},.{0,0,0,0},.{0,0,0,0}};
    for (0..4) |r| {
        for (0..4) |c| { m[r][c] = if (r == c) 1.0 else 0.0; }
    }
    return m;
}
fn scaleMatrix(x:f64,y:f64,z:f64) Matrix { var m=identity();m[0][0]=x;m[1][1]=y;m[2][2]=z;return m; }
fn translateMatrix(x:f64,y:f64,z:f64) Matrix { var m=identity();m[0][3]=x;m[1][3]=y;m[2][3]=z;return m; }
fn multiply(a:Matrix,b:Matrix) Matrix { var out:Matrix=undefined;for(0..4)|r|{for(0..4)|c|{out[r][c]=0;for(0..4)|k|{out[r][c]+=a[r][k]*b[k][c];}}}return out; }
fn rotateMatrix(rx:f64,ry:f64,rz:f64) Matrix {
    const dx=SOURCE_PI/180.0*rx;const dy=SOURCE_PI/180.0*ry;const dz=SOURCE_PI/180.0*rz;
    const cx=@cos(dx);const sx=@sin(dx);const cy=@cos(dy);const sy=@sin(dy);const cz=@cos(dz);const sz=@sin(dz);
    var x=identity();var y=identity();var z=identity();
    x[1][1]=cx;x[1][2]= -sx;x[2][1]=sx;x[2][2]=cx;
    y[0][0]=cy;y[0][2]=sy;y[2][0]= -sy;y[2][2]=cy;
    z[0][0]=cz;z[0][1]= -sz;z[1][0]=sz;z[1][1]=cz;
    return multiply(multiply(x,y),z);
}
fn apply(m:Matrix,p:[3]f64) [3]f64 { var out=[_]f64{0}**3;for(0..3)|r|{out[r]=p[0]*m[r][0]+p[1]*m[r][1]+p[2]*m[r][2]+m[r][3];}return out; }
fn roundMilli(value:f64) i64 { const v=value*1000.0;return @intFromFloat(if(v>=0.0)@floor(v+0.5) else @ceil(v-0.5)); }
fn bounded(value:i64,limit:i64) bool {return value>=-limit and value<=limit;}

pub export fn mccat_08_main(input:?[*]const i64,length:usize) i64 {
    const values=input orelse return -1;
    if(length<HEADER or length>MAX_INPUT)return -1;
    const frames64=values[0];const count64=values[1];
    if(frames64<1 or frames64>360 or count64<1 or count64>MAX_POINTS)return -1;
    const frames:usize=@intCast(frames64);const count:usize=@intCast(count64);
    if(length!=HEADER+3*count)return -1;
    for(2..5)|i|{if(!bounded(values[i],4_000_000))return -1;}
    for(11..14)|i|{if(!bounded(values[i],4_000_000))return -1;}
    for(5..8)|i|{if(!bounded(values[i],360_000_000))return -1;}
    for(14..17)|i|{if(!bounded(values[i],360_000_000))return -1;}
    for(8..11)|i|{if(!bounded(values[i],100_000_000))return -1;}
    for(17..20)|i|{if(!bounded(values[i],100_000_000))return -1;}
    var points: [MAX_POINTS][3]f64 = [_][3]f64{.{0,0,0}} ** MAX_POINTS;
    var raw: [MAX_POINTS][3]i64 = [_][3]i64{.{0,0,0}} ** MAX_POINTS;
    var unique:usize=0;
    for(0..count)|point|{
        const p=[_]i64{values[HEADER+3*point],values[HEADER+3*point+1],values[HEADER+3*point+2]};
        for(p)|v|{if(!bounded(v,100_000_000))return -1;}
        var duplicate=false;
        for(0..unique)|prior|{if(raw[prior][0]==p[0] and raw[prior][1]==p[1] and raw[prior][2]==p[2])duplicate=true;}
        if(!duplicate){raw[unique]=p;for(0..3)|axis|{points[unique][axis]=@as(f64,@floatFromInt(p[axis]))/MICRO;}unique+=1;}
    }
    var checksum:i64=0;
    for(0..frames)|frame|{
        const cs=scaleMatrix(@as(f64,@floatFromInt(values[2]))/MICRO,@as(f64,@floatFromInt(values[3]))/MICRO,@as(f64,@floatFromInt(values[4]))/MICRO);
        const cr=rotateMatrix(@as(f64,@floatFromInt(values[5]))/MICRO,@as(f64,@floatFromInt(values[6]))/MICRO,@as(f64,@floatFromInt(values[7]))/MICRO);
        const ct=translateMatrix(@as(f64,@floatFromInt(values[8]))/MICRO,@as(f64,@floatFromInt(values[9]))/MICRO,@as(f64,@floatFromInt(values[10]))/MICRO);
        const ps=scaleMatrix(@as(f64,@floatFromInt(values[11]))/MICRO,@as(f64,@floatFromInt(values[12]))/MICRO,@as(f64,@floatFromInt(values[13]))/MICRO);
        const pr=rotateMatrix(@as(f64,@floatFromInt(values[14]))/MICRO,@as(f64,@floatFromInt(values[15]))/MICRO+@as(f64,@floatFromInt(frame)),@as(f64,@floatFromInt(values[16]))/MICRO);
        const pt=translateMatrix(@as(f64,@floatFromInt(values[17]))/MICRO,@as(f64,@floatFromInt(values[18]))/MICRO,@as(f64,@floatFromInt(values[19]))/MICRO);
        for(0..unique)|point|{const a=apply(cs,points[point]);const b=apply(cr,a);const c=apply(ct,b);const d=apply(ps,c);const e=apply(pr,d);const f=apply(pt,e);const weight=@as(i64,@intCast(frame+1))*@as(i64,@intCast(point+1));checksum+=weight*(roundMilli(f[0])+3*roundMilli(f[1])+7*roundMilli(f[2]));}
    }
    return checksum;
}
