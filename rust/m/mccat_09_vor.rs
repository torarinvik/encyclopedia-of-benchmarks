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
const MAX_SITES: usize = 8;
const MAX_COORD: i64 = 4;
const CENTER_OFFSET: i64 = 1024;
const CENTER_WIDTH: i64 = 2049;
const RADIUS_RADIX: i64 = 200_000;
#[derive(Clone, Copy)] struct Point { x: i32, y: i32 }
#[derive(Clone, Copy)] struct DPoint { x: f64, y: f64 }
#[derive(Clone, Copy)] struct Priority { radius2: f64, angle: f64 }

fn cross(a: Point,b: Point,c: Point)->i32{(b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)}
fn length2(a:Point,b:Point)->i32{let x=b.x-a.x;let y=b.y-a.y;x*x+y*y}
fn circle_center(a:Point,b:Point,c:Point)->DPoint{
    let (n1x,n1y)=(b.x-a.x,b.y-a.y);let(n2x,n2y)=(c.x-b.x,c.y-b.y);
    let m1x=(f64::from(a.x)+f64::from(b.x))/2.0;let m1y=(f64::from(a.y)+f64::from(b.y))/2.0;
    let m2x=(f64::from(b.x)+f64::from(c.x))/2.0;let m2y=(f64::from(b.y)+f64::from(c.y))/2.0;
    let c1=f64::from(n1x)*m1x+f64::from(n1y)*m1y;let c2=f64::from(n2x)*m2x+f64::from(n2y)*m2y;
    let den=f64::from(n1x)*f64::from(n2y)-f64::from(n1y)*f64::from(n2x);
    DPoint{x:(c1*f64::from(n2y)-f64::from(n1y)*c2)/den,y:(f64::from(n1x)*c2-c1*f64::from(n2x))/den}
}
fn point_key(p:&[Point;MAX_SITES],h:&[usize;MAX_SITES*2],n:usize,i:usize)->Priority{
    let a=p[h[(i+n-1)%n]];let b=p[h[i]];let c=p[h[(i+1)%n]];let o=circle_center(a,b,c);
    let dx=f64::from(b.x)-o.x;let dy=f64::from(b.y)-o.y;
    let ax=f64::from(a.x-b.x);let ay=f64::from(a.y-b.y);let bx=f64::from(c.x-b.x);let by=f64::from(c.y-b.y);
    let dot=ax*bx+ay*by;let v=(dot*dot)/((ax*ax+ay*ay)*(bx*bx+by*by));
    Priority{radius2:dx*dx+dy*dy,angle:if dot<0.0{-v}else{v}}
}
fn make_hull(p:&mut [Point;MAX_SITES],n:usize,h:&mut [usize;MAX_SITES*2])->usize{
    p[..n].sort_by_key(|q|(q.x,q.y));let mut stack=[0usize;MAX_SITES*2];let mut k=0usize;
    for i in 0..n{while k>=2&&cross(p[stack[k-2]],p[stack[k-1]],p[i])<=0{k-=1;}stack[k]=i;k+=1;}
    let threshold=k+1;for i in (0..n-1).rev(){while k>=threshold&&cross(p[stack[k-2]],p[stack[k-1]],p[i])<=0{k-=1;}stack[k]=i;k+=1;}
    k-=1;h[..k].copy_from_slice(&stack[..k]);k
}
fn pack_circle(p:&[Point;MAX_SITES],h:&[usize;MAX_SITES*2])->i64{
    let tri=[p[h[0]],p[h[1]],p[h[2]]];let sides=[length2(tri[0],tri[1]),length2(tri[1],tri[2]),length2(tri[0],tri[2])];
    let(mut opposite,mut u,mut v,mut longest)=(0usize,1usize,2usize,sides[0]);
    if sides[1]>longest{longest=sides[1];opposite=1;u=0;v=2;}if sides[2]>longest{longest=sides[2];opposite=2;u=0;v=1;}
    let o=tri[opposite];let dot=f64::from(tri[u].x-o.x)*f64::from(tri[v].x-o.x)+f64::from(tri[u].y-o.y)*f64::from(tri[v].y-o.y);
    let(center,radius)=if dot<0.0{(DPoint{x:(f64::from(tri[u].x)+f64::from(tri[v].x))/2.0,y:(f64::from(tri[u].y)+f64::from(tri[v].y))/2.0},f64::from(longest).sqrt()/2.0)}else{let c=circle_center(tri[0],tri[1],tri[2]);let dx=f64::from(tri[0].x)-c.x;let dy=f64::from(tri[0].y)-c.y;(c,(dx*dx+dy*dy).sqrt())};
    let cx=center.x as i64;let cy=center.y as i64;let cents=(radius*100.0+0.5) as i64;
    if cx < -CENTER_OFFSET||cx>CENTER_OFFSET||cy < -CENTER_OFFSET||cy>CENTER_OFFSET||cents<0||cents>=RADIUS_RADIX{return -1;}
    ((cx+CENTER_OFFSET)*CENTER_WIDTH+(cy+CENTER_OFFSET))*RADIUS_RADIX+cents
}

#[no_mangle]
pub unsafe extern "C" fn mccat_09_vor(input:*const i64,length:usize)->i64{
    if input.is_null()||length<7||length>17{return -1;}let vals=std::slice::from_raw_parts(input,length);let n=vals[0];
    if n<3||n>MAX_SITES as i64||length!=(1+2*n)as usize{return -1;}let mut p=[Point{x:0,y:0};MAX_SITES];
    for i in 0..n as usize{let(x,y)=(vals[1+2*i],vals[2+2*i]);if x< -MAX_COORD||x>MAX_COORD||y< -MAX_COORD||y>MAX_COORD{return -1;}p[i]=Point{x:x as i32,y:y as i32};for j in 0..i{if p[j].x==p[i].x&&p[j].y==p[i].y{return -1;}}}
    for i in 0..n as usize{for j in i+1..n as usize{for k in j+1..n as usize{if cross(p[i],p[j],p[k])==0{return -1;}}}}
    let mut h=[0usize;MAX_SITES*2];let mut m=make_hull(&mut p,n as usize,&mut h);if m<3||m>MAX_SITES{return -1;}
    while m>3{let mut keys=[Priority{radius2:0.0,angle:0.0};MAX_SITES];for i in 0..m{keys[i]=point_key(&p,&h,m,i);}for i in 0..m{for j in 0..i{if keys[i].radius2==keys[j].radius2&&keys[i].angle==keys[j].angle{return -1;}}}
        let mut best=0;for i in 1..m{if keys[i].radius2>keys[best].radius2||(keys[i].radius2==keys[best].radius2&&keys[i].angle<keys[best].angle){best=i;}}
        for i in best..m-1{h[i]=h[i+1];}m-=1;}
    pack_circle(&p,&h)
}
