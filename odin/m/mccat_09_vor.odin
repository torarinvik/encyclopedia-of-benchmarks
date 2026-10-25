// Copyright (C) 1996 McGill University.
// Copyright (C) 1996 McCAT System Group.
// Copyright (C) 1996 ACAPS Benchmark Administrator
//                    benadmin@acaps.cs.mcgill.ca
//
// This program is free software; you can redistribute it and/or modify
// it provided this copyright notice is maintained.
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
package mccat_09_vor
import "core:c"
import "core:math"

MAX_SITES :: 8
MAX_COORD :: i64(4)
CENTER_OFFSET :: i64(1024)
CENTER_WIDTH :: i64(2049)
RADIUS_RADIX :: i64(200000)
Point :: struct { x, y: i64 }
DPoint :: struct { x, y: f64 }
Priority :: struct { radius2, angle: f64 }

cross :: proc(a,b,c:Point)->i64{return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)}
length2 :: proc(a,b:Point)->i64{x:=b.x-a.x;y:=b.y-a.y;return x*x+y*y}
circle_center :: proc(a,b,c:Point)->DPoint{
    n1x:=b.x-a.x;n1y:=b.y-a.y;n2x:=c.x-b.x;n2y:=c.y-b.y
    m1x:=(f64(a.x)+f64(b.x))/2.0;m1y:=(f64(a.y)+f64(b.y))/2.0
    m2x:=(f64(b.x)+f64(c.x))/2.0;m2y:=(f64(b.y)+f64(c.y))/2.0
    c1:=f64(n1x)*m1x+f64(n1y)*m1y;c2:=f64(n2x)*m2x+f64(n2y)*m2y
    den:=f64(n1x)*f64(n2y)-f64(n1y)*f64(n2x)
    return DPoint{(c1*f64(n2y)-f64(n1y)*c2)/den,(f64(n1x)*c2-c1*f64(n2x))/den}
}
point_key :: proc(p:[^]Point,h:[^]int,n:int,i:int)->Priority{
    a:=p[h[(i+n-1)%n]];b:=p[h[i]];cc:=p[h[(i+1)%n]];o:=circle_center(a,b,cc)
    dx:=f64(b.x)-o.x;dy:=f64(b.y)-o.y;ax:=f64(a.x-b.x);ay:=f64(a.y-b.y);bx:=f64(cc.x-b.x);by:=f64(cc.y-b.y)
    dot:=ax*bx+ay*by;ratio:=(dot*dot)/((ax*ax+ay*ay)*(bx*bx+by*by))
    return Priority{dx*dx+dy*dy,if dot<0.0 then -ratio else ratio}
}
make_hull :: proc(p:[^]Point,n:int,h:[^]int)->int{
    for i:=1;i<n;i+=1{v:=p[i];j:=i;for j>0&&(v.x<p[j-1].x||(v.x==p[j-1].x&&v.y<p[j-1].y)){p[j]=p[j-1];j-=1};p[j]=v}
    stack:[16]int;k:=0
    for i:=0;i<n;i+=1{for k>=2&&cross(p[stack[k-2]],p[stack[k-1]],p[i])<=0{k-=1};stack[k]=i;k+=1}
    threshold:=k+1
    for i:=n-2;i>=0;i-=1{for k>=threshold&&cross(p[stack[k-2]],p[stack[k-1]],p[i])<=0{k-=1};stack[k]=i;k+=1}
    k-=1;for i:=0;i<k;i+=1{h[i]=stack[i]};return k
}
pack_circle :: proc(p:[^]Point,h:[^]int)->i64{
    tri:=[3]Point{p[h[0]],p[h[1]],p[h[2]]};sides:=[3]i64{length2(tri[0],tri[1]),length2(tri[1],tri[2]),length2(tri[0],tri[2])}
    opposite:=0;u:=1;v:=2;longest:=sides[0]
    if sides[1]>longest{longest=sides[1];opposite=1;u=0;v=2};if sides[2]>longest{longest=sides[2];opposite=2;u=0;v=1}
    o:=tri[opposite];dot:=f64(tri[u].x-o.x)*f64(tri[v].x-o.x)+f64(tri[u].y-o.y)*f64(tri[v].y-o.y)
    center:DPoint;radius:f64
    if dot<0.0{center=DPoint{(f64(tri[u].x)+f64(tri[v].x))/2.0,(f64(tri[u].y)+f64(tri[v].y))/2.0};radius=math.sqrt(f64(longest))/2.0}
    else{center=circle_center(tri[0],tri[1],tri[2]);dx:=f64(tri[0].x)-center.x;dy:=f64(tri[0].y)-center.y;radius=math.sqrt(dx*dx+dy*dy)}
    cx:=i64(center.x);cy:=i64(center.y);cents:=i64(radius*100.0+0.5)
    if cx < -CENTER_OFFSET||cx>CENTER_OFFSET||cy < -CENTER_OFFSET||cy>CENTER_OFFSET||cents<0||cents>=RADIUS_RADIX{return -1}
    return ((cx+CENTER_OFFSET)*CENTER_WIDTH+(cy+CENTER_OFFSET))*RADIUS_RADIX+cents
}
@(export)
mccat_09_vor :: proc "c" (input:[^]i64,length:c.size_t)->i64{
    if input==nil||length<7||length>17 do return -1
    n:=input[0];if n<3||n>MAX_SITES||length!=c.size_t(1+2*n) do return -1
    points:[MAX_SITES]Point
    for i:=0;i<int(n);i+=1{x:=input[1+2*i];y:=input[2+2*i];if x < -MAX_COORD||x>MAX_COORD||y < -MAX_COORD||y>MAX_COORD do return -1;points[i]=Point{x,y};for j:=0;j<i;j+=1{if points[j].x==x&&points[j].y==y do return -1}}
    for i:=0;i<int(n);i+=1{for j:=i+1;j<int(n);j+=1{for k:=j+1;k<int(n);k+=1{if cross(points[i],points[j],points[k])==0 do return -1}}}
    hull:[16]int;m:=make_hull(&points[0],int(n),&hull[0]);if m<3||m>MAX_SITES do return -1
    for m>3{keys:[MAX_SITES]Priority;for i:=0;i<m;i+=1{keys[i]=point_key(&points[0],&hull[0],m,i)};for i:=0;i<m;i+=1{for j:=0;j<i;j+=1{if keys[i].radius2==keys[j].radius2&&keys[i].angle==keys[j].angle do return -1}}
        best:=0;for i:=1;i<m;i+=1{if keys[i].radius2>keys[best].radius2||(keys[i].radius2==keys[best].radius2&&keys[i].angle<keys[best].angle){best=i}}
        for i:=best;i<m-1;i+=1{hull[i]=hull[i+1]};m-=1}
    return pack_circle(&points[0],&hull[0])
}
