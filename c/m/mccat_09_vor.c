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
#include <stddef.h>
#include <stdint.h>
#include <math.h>

#define MAX_SITES 8
#define MAX_COORD 4
#define CENTER_OFFSET 1024
#define CENTER_WIDTH 2049
#define RADIUS_RADIX 200000

typedef struct { int x, y; } Point;
typedef struct { double x, y; } DPoint;
typedef struct { double radius2, angle; } Priority;

static int cross(Point a, Point b, Point c) {
    return (b.x-a.x)*(c.y-a.y) - (b.y-a.y)*(c.x-a.x);
}

static int length2(Point a, Point b) {
    int dx = b.x-a.x, dy = b.y-a.y;
    return dx*dx + dy*dy;
}

/* Keep the source's bisector-intersection operation order. */
static DPoint circle_center(Point p1, Point p2, Point p3) {
    int n1x=p2.x-p1.x, n1y=p2.y-p1.y;
    int n2x=p3.x-p2.x, n2y=p3.y-p2.y;
    double m1x=((double)p1.x+p2.x)/2.0, m1y=((double)p1.y+p2.y)/2.0;
    double m2x=((double)p2.x+p3.x)/2.0, m2y=((double)p2.y+p3.y)/2.0;
    double c1=(double)n1x*m1x+(double)n1y*m1y;
    double c2=(double)n2x*m2x+(double)n2y*m2y;
    double den=(double)n1x*n2y-(double)n1y*n2x;
    DPoint out={(c1*n2y-(double)n1y*c2)/den,
                ((double)n1x*c2-c1*n2x)/den};
    return out;
}

static int point_key(Point *points, int *hull, int count, int pos, Priority *key) {
    Point prev=points[hull[(pos+count-1)%count]];
    Point cur=points[hull[pos]];
    Point next=points[hull[(pos+1)%count]];
    DPoint center=circle_center(prev,cur,next);
    double dx=(double)cur.x-center.x, dy=(double)cur.y-center.y;
    key->radius2=dx*dx+dy*dy;
    double ax=(double)prev.x-cur.x, ay=(double)prev.y-cur.y;
    double bx=(double)next.x-cur.x, by=(double)next.y-cur.y;
    double dot=ax*bx+ay*by, la2=ax*ax+ay*ay, lb2=bx*bx+by*by;
    double v=(dot*dot)/(la2*lb2);
    key->angle=dot<0.0 ? -v : v;
    return 1;
}

static int compare_point(Point a, Point b) {
    return a.x < b.x || (a.x == b.x && a.y < b.y);
}

static int make_hull(Point *points, int n, int *hull) {
    for (int i=1;i<n;i++) {
        Point v=points[i]; int j=i;
        while (j>0 && compare_point(v,points[j-1])) { points[j]=points[j-1]; --j; }
        points[j]=v;
    }
    int stack[2*MAX_SITES], k=0;
    for (int i=0;i<n;i++) {
        while (k>=2 && cross(points[stack[k-2]],points[stack[k-1]],points[i])<=0) --k;
        stack[k++]=i;
    }
    int lower=k, threshold=k+1;
    for (int i=n-2;i>=0;i--) {
        while (k>=threshold && cross(points[stack[k-2]],points[stack[k-1]],points[i])<=0) --k;
        stack[k++]=i;
    }
    --k;
    for (int i=0;i<k;i++) hull[i]=stack[i];
    (void)lower;
    return k;
}

static int64_t pack_circle(Point *points, int *hull) {
    Point p[3]={points[hull[0]],points[hull[1]],points[hull[2]]};
    int side[3]={length2(p[0],p[1]),length2(p[1],p[2]),length2(p[0],p[2])};
    int opposite=0, a=1, b=2, longest=side[0];
    if (side[1]>longest) { longest=side[1]; opposite=1; a=0; b=2; }
    if (side[2]>longest) { longest=side[2]; opposite=2; a=0; b=1; }
    Point v=p[opposite];
    int ux=p[a].x-v.x, uy=p[a].y-v.y, vx=p[b].x-v.x, vy=p[b].y-v.y;
    double dot=(double)ux*vx+(double)uy*vy;
    DPoint center;
    double radius;
    if (dot<0.0) {
        center.x=((double)p[a].x+p[b].x)/2.0;
        center.y=((double)p[a].y+p[b].y)/2.0;
        radius=sqrt((double)longest)/2.0;
    } else {
        center=circle_center(p[0],p[1],p[2]);
        double dx=(double)p[0].x-center.x, dy=(double)p[0].y-center.y;
        radius=sqrt(dx*dx+dy*dy);
    }
    int cx=(int)center.x, cy=(int)center.y;
    int64_t cents=(int64_t)(radius*100.0+0.5);
    if (cx < -CENTER_OFFSET || cx > CENTER_OFFSET || cy < -CENTER_OFFSET ||
        cy > CENTER_OFFSET || cents < 0 || cents >= RADIUS_RADIX) return -1;
    return (int64_t)(((int64_t)(cx+CENTER_OFFSET)*CENTER_WIDTH+(cy+CENTER_OFFSET))*RADIUS_RADIX+cents);
}

int64_t mccat_09_vor(const int64_t *input, size_t length) {
    if (input==NULL || length<7 || length>1+2*MAX_SITES) return -1;
    int64_t count=input[0];
    if (count<3 || count>MAX_SITES || length!=(size_t)(1+2*count)) return -1;
    Point points[MAX_SITES];
    for (int i=0;i<(int)count;i++) {
        int64_t x=input[1+2*i], y=input[2+2*i];
        if (x < -MAX_COORD || x > MAX_COORD || y < -MAX_COORD || y > MAX_COORD) return -1;
        points[i]=(Point){(int)x,(int)y};
        for (int j=0;j<i;j++) if (points[j].x==points[i].x && points[j].y==points[i].y) return -1;
    }
    for (int i=0;i<(int)count;i++) for (int j=i+1;j<(int)count;j++)
        for (int k=j+1;k<(int)count;k++) if (cross(points[i],points[j],points[k])==0) return -1;
    int hull[2*MAX_SITES];
    int hull_count=make_hull(points,(int)count,hull);
    if (hull_count<3 || hull_count>MAX_SITES) return -1;
    while (hull_count>3) {
        Priority keys[MAX_SITES];
        for (int i=0;i<hull_count;i++) point_key(points,hull,hull_count,i,&keys[i]);
        for (int i=0;i<hull_count;i++) for (int j=0;j<i;j++)
            if (keys[i].radius2==keys[j].radius2 && keys[i].angle==keys[j].angle) return -1;
        int best=0;
        for (int i=1;i<hull_count;i++)
            if (keys[i].radius2>keys[best].radius2 ||
                (keys[i].radius2==keys[best].radius2 && keys[i].angle<keys[best].angle)) best=i;
        for (int i=best;i<hull_count-1;i++) hull[i]=hull[i+1];
        --hull_count;
    }
    return pack_circle(points,hull);
}
