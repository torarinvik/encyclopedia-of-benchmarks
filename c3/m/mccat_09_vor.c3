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
module mccat_09_vor;

const int MAX_SITES = 8;
const int MAX_COORD = 4;
const long CENTER_OFFSET = 1024;
const long CENTER_WIDTH = 2049;
const long RADIUS_RADIX = 200000;
extern fn double sqrt(double value);

struct Point { int x; int y; }
struct DPoint { double x; double y; }
struct Priority { double radius2; double angle; }

fn int cross(Point a, Point b, Point c) { return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x); }
fn int length2(Point a, Point b) { int x=b.x-a.x, y=b.y-a.y; return x*x+y*y; }

fn DPoint circle_center(Point a, Point b, Point c) {
    int n1x=b.x-a.x, n1y=b.y-a.y, n2x=c.x-b.x, n2y=c.y-b.y;
    double m1x=((double)a.x+b.x)/2.0, m1y=((double)a.y+b.y)/2.0;
    double m2x=((double)b.x+c.x)/2.0, m2y=((double)b.y+c.y)/2.0;
    double c1=(double)n1x*m1x+(double)n1y*m1y, c2=(double)n2x*m2x+(double)n2y*m2y;
    double den=(double)n1x*n2y-(double)n1y*n2x;
    return {(c1*n2y-(double)n1y*c2)/den, ((double)n1x*c2-c1*n2x)/den};
}

fn Priority point_key(Point* p, int* h, int n, int i) {
    Point a=p[h[(i+n-1)%n]], b=p[h[i]], c=p[h[(i+1)%n]];
    DPoint o=circle_center(a,b,c); double dx=(double)b.x-o.x, dy=(double)b.y-o.y;
    double ax=(double)(a.x-b.x), ay=(double)(a.y-b.y), bx=(double)(c.x-b.x), by=(double)(c.y-b.y);
    double dot=ax*bx+ay*by, la=ax*ax+ay*ay, lb=bx*bx+by*by, v=(dot*dot)/(la*lb);
    return {dx*dx+dy*dy, dot<0.0 ? -v : v};
}

fn int make_hull(Point* p, int n, int* h) {
    for (int i=1;i<n;i++) { Point v=p[i]; int j=i; while (j>0 && (v.x<p[j-1].x || (v.x==p[j-1].x && v.y<p[j-1].y))) { p[j]=p[j-1]; j--; } p[j]=v; }
    int stack[16], k=0;
    for (int i=0;i<n;i++) { while (k>=2 && cross(p[stack[k-2]],p[stack[k-1]],p[i])<=0) k--; stack[k++]=i; }
    int threshold=k+1;
    for (int i=n-2;i>=0;i--) { while (k>=threshold && cross(p[stack[k-2]],p[stack[k-1]],p[i])<=0) k--; stack[k++]=i; }
    k--; for (int i=0;i<k;i++) h[i]=stack[i]; return k;
}

fn long pack_circle(Point* p, int* h) {
    Point a=p[h[0]], b=p[h[1]], c=p[h[2]];
    int s0=length2(a,b), s1=length2(b,c), s2=length2(a,c), opposite=0, u=1, v=2, longest=s0;
    if (s1>longest) { longest=s1; opposite=1; u=0; v=2; }
    if (s2>longest) { longest=s2; opposite=2; u=0; v=1; }
    Point tri[3]={a,b,c}, o=tri[opposite];
    double dot=(double)(tri[u].x-o.x)*(tri[v].x-o.x)+(double)(tri[u].y-o.y)*(tri[v].y-o.y);
    DPoint center; double radius;
    if (dot<0.0) { center={(double)(tri[u].x+tri[v].x)/2.0,(double)(tri[u].y+tri[v].y)/2.0}; radius=sqrt((double)longest)/2.0; }
    else { center=circle_center(a,b,c); double dx=(double)a.x-center.x, dy=(double)a.y-center.y; radius=sqrt(dx*dx+dy*dy); }
    int cx=(int)center.x, cy=(int)center.y; long cents=(long)(radius*100.0+0.5);
    if (cx < -CENTER_OFFSET || cx > CENTER_OFFSET || cy < -CENTER_OFFSET || cy > CENTER_OFFSET || cents < 0 || cents >= RADIUS_RADIX) return -1;
    return ((long)(cx+CENTER_OFFSET)*CENTER_WIDTH+(cy+CENTER_OFFSET))*RADIUS_RADIX+cents;
}

fn long mccat_09_vor(long* input, usz length) @export("mccat_09_vor") {
    if (input==null || length<7 || length>17) return -1;
    long n=input[0]; if (n<3 || n>MAX_SITES || length!=(usz)(1+2*n)) return -1;
    Point[MAX_SITES] p;
    for (int i=0;i<(int)n;i++) {
        long x=input[1+2*i], y=input[2+2*i];
        if (x < -MAX_COORD || x > MAX_COORD || y < -MAX_COORD || y > MAX_COORD) return -1;
        p[i]={(int)x,(int)y};
        for (int j=0;j<i;j++) if (p[j].x==p[i].x && p[j].y==p[i].y) return -1;
    }
    for (int i=0;i<(int)n;i++) for (int j=i+1;j<(int)n;j++) for (int k=j+1;k<(int)n;k++) if (cross(p[i],p[j],p[k])==0) return -1;
    int[16] h; int m=make_hull(&p[0],(int)n,&h[0]); if (m<3 || m>MAX_SITES) return -1;
    while (m>3) {
        Priority[MAX_SITES] keys;
        for (int i=0;i<m;i++) keys[i]=point_key(&p[0],&h[0],m,i);
        for (int i=0;i<m;i++) for (int j=0;j<i;j++) if (keys[i].radius2==keys[j].radius2 && keys[i].angle==keys[j].angle) return -1;
        int best=0;
        for (int i=1;i<m;i++) if (keys[i].radius2>keys[best].radius2 || (keys[i].radius2==keys[best].radius2 && keys[i].angle<keys[best].angle)) best=i;
        for (int i=best;i<m-1;i++) h[i]=h[i+1]; m--;
    }
    return pack_circle(&p[0],&h[0]);
}
