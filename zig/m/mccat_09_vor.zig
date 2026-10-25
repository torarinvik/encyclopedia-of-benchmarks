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
const MAX_SITES: usize = 8;
const MAX_COORD: i64 = 4;
const CENTER_OFFSET: i64 = 1024;
const CENTER_WIDTH: i64 = 2049;
const RADIUS_RADIX: i64 = 200_000;

const Point = struct { x: i64, y: i64 };
const DPoint = struct { x: f64, y: f64 };
const Priority = struct { radius2: f64, angle: f64 };

fn cross(a: Point, b: Point, c: Point) i64 {
    return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x);
}
fn length2(a: Point, b: Point) i64 {
    const dx=b.x-a.x; const dy=b.y-a.y; return dx*dx+dy*dy;
}
fn circleCenter(a: Point, b: Point, c: Point) DPoint {
    const n1x=b.x-a.x; const n1y=b.y-a.y; const n2x=c.x-b.x; const n2y=c.y-b.y;
    const m1x=(@as(f64,@floatFromInt(a.x))+@as(f64,@floatFromInt(b.x)))/2.0;
    const m1y=(@as(f64,@floatFromInt(a.y))+@as(f64,@floatFromInt(b.y)))/2.0;
    const m2x=(@as(f64,@floatFromInt(b.x))+@as(f64,@floatFromInt(c.x)))/2.0;
    const m2y=(@as(f64,@floatFromInt(b.y))+@as(f64,@floatFromInt(c.y)))/2.0;
    const c1=@as(f64,@floatFromInt(n1x))*m1x+@as(f64,@floatFromInt(n1y))*m1y;
    const c2=@as(f64,@floatFromInt(n2x))*m2x+@as(f64,@floatFromInt(n2y))*m2y;
    const den=@as(f64,@floatFromInt(n1x))*@as(f64,@floatFromInt(n2y))-@as(f64,@floatFromInt(n1y))*@as(f64,@floatFromInt(n2x));
    return .{ .x=(c1*@as(f64,@floatFromInt(n2y))-@as(f64,@floatFromInt(n1y))*c2)/den,
               .y=(@as(f64,@floatFromInt(n1x))*c2-c1*@as(f64,@floatFromInt(n2x)))/den };
}
fn pointKey(points: *const [MAX_SITES]Point, hull: *const [MAX_SITES*2]usize, n: usize, i: usize) Priority {
    const a=points.*[hull.*[(i+n-1)%n]]; const b=points.*[hull.*[i]]; const c=points.*[hull.*[(i+1)%n]];
    const center=circleCenter(a,b,c);
    const dx=@as(f64,@floatFromInt(b.x))-center.x; const dy=@as(f64,@floatFromInt(b.y))-center.y;
    const ax=@as(f64,@floatFromInt(a.x-b.x)); const ay=@as(f64,@floatFromInt(a.y-b.y));
    const bx=@as(f64,@floatFromInt(c.x-b.x)); const by=@as(f64,@floatFromInt(c.y-b.y));
    const dot=ax*bx+ay*by; const ratio=(dot*dot)/((ax*ax+ay*ay)*(bx*bx+by*by));
    return .{ .radius2=dx*dx+dy*dy, .angle=if(dot<0.0) -ratio else ratio };
}
fn makeHull(points: *[MAX_SITES]Point, n: usize, hull: *[MAX_SITES*2]usize) usize {
    for (1..n) |i| {
        const value=points.*[i]; var j=i;
        while(j>0 and (value.x<points.*[j-1].x or (value.x==points.*[j-1].x and value.y<points.*[j-1].y))){points.*[j]=points.*[j-1];j-=1;}
        points.*[j]=value;
    }
    var stack=[_]usize{0} ** (MAX_SITES*2); var k:usize=0;
    for(0..n) |i| { while(k>=2 and cross(points.*[stack[k-2]],points.*[stack[k-1]],points.*[i])<=0){k-=1;} stack[k]=i;k+=1; }
    const threshold=k+1;
    var i=n-1;
    while(i>0){i-=1;while(k>=threshold and cross(points.*[stack[k-2]],points.*[stack[k-1]],points.*[i])<=0){k-=1;}stack[k]=i;k+=1;}
    k-=1;for(0..k) |index| hull.*[index]=stack[index];return k;
}
fn packCircle(points: *const [MAX_SITES]Point, hull: *const [MAX_SITES*2]usize) i64 {
    const tri=[_]Point{points.*[hull.*[0]],points.*[hull.*[1]],points.*[hull.*[2]]};
    const sides=[_]i64{length2(tri[0],tri[1]),length2(tri[1],tri[2]),length2(tri[0],tri[2])};
    var opposite:usize=0;var u:usize=1;var v:usize=2;var longest=sides[0];
    if(sides[1]>longest){longest=sides[1];opposite=1;u=0;v=2;}if(sides[2]>longest){longest=sides[2];opposite=2;u=0;v=1;}
    const o=tri[opposite];const dot=@as(f64,@floatFromInt(tri[u].x-o.x))*@as(f64,@floatFromInt(tri[v].x-o.x))+@as(f64,@floatFromInt(tri[u].y-o.y))*@as(f64,@floatFromInt(tri[v].y-o.y));
    var center:DPoint=undefined;var radius:f64=undefined;
    if(dot<0.0){center=.{.x=(@as(f64,@floatFromInt(tri[u].x))+@as(f64,@floatFromInt(tri[v].x)))/2.0,.y=(@as(f64,@floatFromInt(tri[u].y))+@as(f64,@floatFromInt(tri[v].y)))/2.0};radius=@sqrt(@as(f64,@floatFromInt(longest)))/2.0;}
    else{center=circleCenter(tri[0],tri[1],tri[2]);const dx=@as(f64,@floatFromInt(tri[0].x))-center.x;const dy=@as(f64,@floatFromInt(tri[0].y))-center.y;radius=@sqrt(dx*dx+dy*dy);}
    const cx:i64=@intFromFloat(center.x);const cy:i64=@intFromFloat(center.y);const cents:i64=@intFromFloat(radius*100.0+0.5);
    if(cx < -CENTER_OFFSET or cx>CENTER_OFFSET or cy < -CENTER_OFFSET or cy>CENTER_OFFSET or cents<0 or cents>=RADIUS_RADIX)return -1;
    return ((cx+CENTER_OFFSET)*CENTER_WIDTH+(cy+CENTER_OFFSET))*RADIUS_RADIX+cents;
}

pub export fn mccat_09_vor(input: ?[*]const i64, length: usize) i64 {
    const values=input orelse return -1;
    if(length<7 or length>17)return -1;
    const n64=values[0];if(n64<3 or n64>@as(i64,@intCast(MAX_SITES)) or length!=1+2*@as(usize,@intCast(n64)))return -1;
    const n:usize=@intCast(n64);var points=[_]Point{.{.x=0,.y=0}} ** MAX_SITES;
    for(0..n) |i| {const x=values[1+2*i];const y=values[2+2*i];if(x < -MAX_COORD or x>MAX_COORD or y < -MAX_COORD or y>MAX_COORD)return -1;points[i]=.{.x=x,.y=y};for(0..i) |j|{if(points[j].x==x and points[j].y==y)return -1;}}
    for(0..n) |i|{for(i+1..n) |j|{for(j+1..n) |k|{if(cross(points[i],points[j],points[k])==0)return -1;}}}
    var hull=[_]usize{0} ** (MAX_SITES*2);var count=makeHull(&points,n,&hull);if(count<3 or count>MAX_SITES)return -1;
    while(count>3){var keys=[_]Priority{.{.radius2=0.0,.angle=0.0}} ** MAX_SITES;for(0..count) |i|{keys[i]=pointKey(&points,&hull,count,i);}
        for(0..count) |i|{for(0..i) |j|{if(keys[i].radius2==keys[j].radius2 and keys[i].angle==keys[j].angle)return -1;}}
        var best:usize=0;for(1..count) |i|{if(keys[i].radius2>keys[best].radius2 or (keys[i].radius2==keys[best].radius2 and keys[i].angle<keys[best].angle)){best=i;}}
        for(best..count-1) |i|{hull[i]=hull[i+1];}count-=1;
    }
    return packCircle(&points,&hull);
}
