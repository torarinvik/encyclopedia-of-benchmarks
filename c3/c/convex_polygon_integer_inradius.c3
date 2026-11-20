// Independently authored draft; not compiled or run.
module convex_polygon_integer_inradius;
struct Line { long a,b,c,norm; }
struct Point { long x,y,den; }
fn long abs64(long x) { return x<0 ? -x : x; }
fn long gcd64(long a,long b) {
    a=abs64(a); b=abs64(b);
    while (b!=0) { long r=a%b; a=b; b=r; }
    return a;
}
fn int half(Line l) { return l.b>0 || (l.b==0 && l.a>=0) ? 0 : 1; }
fn bool before(Line a,Line b) {
    int ha=half(a), hb=half(b);
    if (ha!=hb) return ha<hb;
    long cross=a.a*b.b-a.b*b.a;
    return cross!=0 ? cross>0 : a.c<b.c;
}
fn bool intersect(Line a,Line b,Point* p) {
    long den=a.a*b.b-b.a*a.b;
    if (den==0) return false;
    long x=a.c*b.b-a.b*b.c, y=a.a*b.c-a.c*b.a;
    if (den<0) { den=-den; x=-x; y=-y; }
    p.x=x; p.y=y; p.den=den; return true;
}
fn bool outside(Line l,Point p) { return l.a*p.x+l.b*p.y>l.c*p.den; }
fn bool feasible(Line* lines,int count,long radius) {
    Line[16] queue={}; int head=0,tail=0;
    for (int i=0;i<count;i++) {
        Line h=lines[i]; h.c=h.c*32768-(radius*32768-1)*h.norm;
        if (tail>head && queue[tail-1].a==h.a && queue[tail-1].b==h.b) {
            if (h.c>=queue[tail-1].c) continue;
            tail--;
        }
        Point p={};
        while (tail-head>1 && intersect(queue[tail-2],queue[tail-1],&p) && outside(h,p)) tail--;
        while (tail-head>1 && intersect(queue[head],queue[head+1],&p) && outside(h,p)) head++;
        if (tail>head && queue[tail-1].a*h.b-queue[tail-1].b*h.a==0) return false;
        queue[tail++]=h;
    }
    Point p={};
    while (tail-head>2 && intersect(queue[tail-2],queue[tail-1],&p) && outside(queue[head],p)) tail--;
    while (tail-head>2 && intersect(queue[head],queue[head+1],&p) && outside(queue[tail-1],p)) head++;
    if (tail-head<3) return false;
    for (int i=head;i<tail;i++)
        if (!intersect(queue[i],queue[i+1==tail ? head : i+1],&p)) return false;
    return true;
}
fn long convex_polygon_integer_inradius(long* values,usz length)
        @export("convex_polygon_integer_inradius") {
    if (values==null || length<1 || length>38 || values[0]<0 || values[0]>12) return -1;
    int n=(int)values[0];
    if (length!=(usz)(1+3*n)) return -1;
    Line[16] lines={};
    for (int i=0;i<n;i++) {
        long a=values[1+3*i], b=values[2+3*i], c=values[3+3*i];
        if (a < -15 || a>15 || b < -15 || b>15 || c < -128 || c>128) return -1;
        long squared=a*a+b*b, norm=0;
        while (norm*norm<squared) norm++;
        if (norm==0 || norm*norm!=squared || gcd64(a,b)!=1) return -1;
        lines[i]=(Line){a,b,c,norm};
    }
    lines[n++]=(Line){1,0,256,1}; lines[n++]=(Line){0,1,256,1};
    lines[n++]=(Line){-1,0,256,1}; lines[n++]=(Line){0,-1,256,1};
    Line[16] scratch={};
    for (int width=1;width<n;width*=2) {
        for (int start=0;start<n;start+=2*width) {
            int middle=start+width<n ? start+width : n;
            int end=start+2*width<n ? start+2*width : n;
            int i=start,j=middle,k=start;
            while (i<middle && j<end) scratch[k++]=before(lines[j],lines[i]) ? lines[j++] : lines[i++];
            while (i<middle) scratch[k++]=lines[i++];
            while (j<end) scratch[k++]=lines[j++];
        }
        for (int i=0;i<n;i++) lines[i]=scratch[i];
    }
    if (!feasible(&lines[0],n,0)) return -2;
    long low=0,high=257;
    while (high-low>1) {
        long middle=(low+high)/2;
        if (feasible(&lines[0],n,middle)) low=middle; else high=middle;
    }
    return low;
}
