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
module mccat_09_vor

import math

const max_sites = 8
const max_coord = 4
const center_offset = i64(1024)
const center_width = i64(2049)
const radius_radix = i64(200000)

struct Point { x int; y int }
struct DPoint { x f64; y f64 }
struct Priority { radius2 f64; angle f64 }

fn cross(a Point, b Point, c Point) int {
	return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)
}
fn length2(a Point, b Point) int {
	dx:=b.x-a.x; dy:=b.y-a.y
	return dx*dx+dy*dy
}
fn circle_center(a Point, b Point, c Point) DPoint {
	n1x:=b.x-a.x; n1y:=b.y-a.y; n2x:=c.x-b.x; n2y:=c.y-b.y
	m1x:=(f64(a.x)+f64(b.x))/2.0; m1y:=(f64(a.y)+f64(b.y))/2.0
	m2x:=(f64(b.x)+f64(c.x))/2.0; m2y:=(f64(b.y)+f64(c.y))/2.0
	c1:=f64(n1x)*m1x+f64(n1y)*m1y; c2:=f64(n2x)*m2x+f64(n2y)*m2y
	den:=f64(n1x)*f64(n2y)-f64(n1y)*f64(n2x)
	return DPoint{(c1*f64(n2y)-f64(n1y)*c2)/den,(f64(n1x)*c2-c1*f64(n2x))/den}
}
fn point_key(p [max_sites]Point, h [max_sites*2]int, n int, i int) Priority {
	a:=p[h[(i+n-1)%n]]; b:=p[h[i]]; c:=p[h[(i+1)%n]]; o:=circle_center(a,b,c)
	dx:=f64(b.x)-o.x; dy:=f64(b.y)-o.y
	ax:=f64(a.x-b.x); ay:=f64(a.y-b.y); bx:=f64(c.x-b.x); by:=f64(c.y-b.y)
	dot:=ax*bx+ay*by; ratio:=(dot*dot)/((ax*ax+ay*ay)*(bx*bx+by*by))
	return Priority{dx*dx+dy*dy,if dot<0.0{-ratio}else{ratio}}
}
fn make_hull(mut p [max_sites]Point, n int, mut h [max_sites*2]int) int {
	for i:=1;i<n;i++ {
		value:=p[i]; mut j:=i
		for j>0&&(value.x<p[j-1].x||(value.x==p[j-1].x&&value.y<p[j-1].y)){p[j]=p[j-1];j--}
		p[j]=value
	}
	mut stack:=[max_sites*2]int{}; mut k:=0
	for i:=0;i<n;i++ {for k>=2&&cross(p[stack[k-2]],p[stack[k-1]],p[i])<=0{k--};stack[k]=i;k++}
	threshold:=k+1
	for i:=n-2;i>=0;i-- {for k>=threshold&&cross(p[stack[k-2]],p[stack[k-1]],p[i])<=0{k--};stack[k]=i;k++}
	k--;for i:=0;i<k;i++{h[i]=stack[i]};return k
}
fn pack_circle(p [max_sites]Point, h [max_sites*2]int) i64 {
	tri:=[3]Point{p[h[0]],p[h[1]],p[h[2]]}
	sides:=[3]int{length2(tri[0],tri[1]),length2(tri[1],tri[2]),length2(tri[0],tri[2])}
	mut opposite:=0;mut u:=1;mut v:=2;mut longest:=sides[0]
	if sides[1]>longest{longest=sides[1];opposite=1;u=0;v=2};if sides[2]>longest{longest=sides[2];opposite=2;u=0;v=1}
	o:=tri[opposite];dot:=f64(tri[u].x-o.x)*f64(tri[v].x-o.x)+f64(tri[u].y-o.y)*f64(tri[v].y-o.y)
	mut center:=DPoint{};mut radius:=f64(0)
	if dot<0.0{center=DPoint{(f64(tri[u].x)+f64(tri[v].x))/2.0,(f64(tri[u].y)+f64(tri[v].y))/2.0};radius=math.sqrt(f64(longest))/2.0}
	else{center=circle_center(tri[0],tri[1],tri[2]);dx:=f64(tri[0].x)-center.x;dy:=f64(tri[0].y)-center.y;radius=math.sqrt(dx*dx+dy*dy)}
	cx:=i64(center.x);cy:=i64(center.y);cents:=i64(radius*100.0+0.5)
	if cx < -center_offset||cx>center_offset||cy < -center_offset||cy>center_offset||cents<0||cents>=radius_radix{return -1}
	return ((cx+center_offset)*center_width+(cy+center_offset))*radius_radix+cents
}

@[export: 'mccat_09_vor']
pub fn mccat_09_vor(input &i64, length usize) i64 {
	unsafe {
		if input==nil||length<7||length>17{return -1}
		count64:=input[0];if count64<3||count64>max_sites||length!=usize(1+2*count64){return -1}
		count:=int(count64);mut p:=[max_sites]Point{};mut h:=[max_sites*2]int{}
		for i:=0;i<count;i++{x:=input[1+2*i];y:=input[2+2*i];if x < -max_coord||x>max_coord||y < -max_coord||y>max_coord{return -1};p[i]=Point{int(x),int(y)};for j:=0;j<i;j++{if p[j].x==int(x)&&p[j].y==int(y){return -1}}}
		for i:=0;i<count;i++{for j:=i+1;j<count;j++{for k:=j+1;k<count;k++{if cross(p[i],p[j],p[k])==0{return -1}}}}
		n:=make_hull(mut p,count,mut h);if n<3||n>max_sites{return -1}
		for n>3{mut keys:=[max_sites]Priority{};for i:=0;i<n;i++{keys[i]=point_key(p,h,n,i)};for i:=0;i<n;i++{for j:=0;j<i;j++{if keys[i].radius2==keys[j].radius2&&keys[i].angle==keys[j].angle{return -1}}};mut best:=0;for i:=1;i<n;i++{if keys[i].radius2>keys[best].radius2||(keys[i].radius2==keys[best].radius2&&keys[i].angle<keys[best].angle){best=i}};for i:=best;i<n-1;i++{h[i]=h[i+1]};n--}
		return pack_circle(p,h)
	}
}
