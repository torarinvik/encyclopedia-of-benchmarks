// Independently authored draft; not compiled or run.
module half_plane_intersection_incremental_clipping;
struct ClipLine { long a,b,c; }
struct ClipVertex { long x,y,den; int incoming; }
fn long clip_gcd(long a, long b) {
    if (a<0) a=-a; if (b<0) b=-b;
    while (b!=0) { long r=a%b; a=b; b=r; }
    return a;
}
fn bool clip_intersect(ClipLine a, ClipLine b, ClipVertex* p) {
    long d=a.a*b.b-b.a*a.b;
    if (d==0) return false;
    long x=a.c*b.b-a.b*b.c, y=a.a*b.c-a.c*b.a;
    if (d<0) { d=-d; x=-x; y=-y; }
    long g=clip_gcd(clip_gcd(x,y),d);
    p.x=x/g; p.y=y/g; p.den=d/g; return true;
}
fn long clip_side(ClipLine l, ClipVertex p) { return l.a*p.x+l.b*p.y-l.c*p.den; }
fn bool clip_same(ClipVertex a, ClipVertex b) { return a.x*b.den==b.x*a.den && a.y*b.den==b.y*a.den; }
fn long clip_turn(ClipVertex a, ClipVertex b, ClipVertex c) {
    long dx1=b.x*a.den-a.x*b.den, dy1=b.y*a.den-a.y*b.den;
    long dx2=c.x*b.den-b.x*c.den, dy2=c.y*b.den-b.y*c.den;
    return dx1*dy2-dy1*dx2;
}
fn void clip_append(ClipVertex* out, int* used, ClipVertex p) {
    if (*used==0 || !clip_same(out[*used-1],p)) { out[*used]=p; *used+=1; }
}
fn void clip_put(char* out, usz* offset, long value) {
    ulong bits=(ulong)value;
    for (int i=0;i<8;i++) { out[*offset]=(char)(bits>>(8*i)); *offset+=1; }
}
fn long half_plane_intersection_incremental_clipping(long* input, usz length, char* output, usz capacity)
    @export("half_plane_intersection_incremental_clipping") {
    if (input==null || length<1 || length>38 || input[0]<0 || input[0]>12) return -1;
    int n=(int)input[0];
    if (length != 1+3*(usz)n) return -1;
    ClipLine[16] lines=zeroed;
    lines[0]=(ClipLine){-1,0,256}; lines[1]=(ClipLine){0,-1,256};
    lines[2]=(ClipLine){1,0,256}; lines[3]=(ClipLine){0,1,256};
    for (int i=0;i<n;i++) {
        long a=input[1+3*i], b=input[2+3*i], c=input[3+3*i];
        if (a < -16 || a > 16 || b < -16 || b > 16 || c < -128 || c > 128 || (a==0 && b==0) || clip_gcd(a,b)!=1) return -1;
        lines[4+i]=(ClipLine){a,b,c};
    }
    ClipVertex[32] polygon=zeroed;
    polygon[0]=(ClipVertex){-256,-256,1,0}; polygon[1]=(ClipVertex){256,-256,1,1};
    polygon[2]=(ClipVertex){256,256,1,2}; polygon[3]=(ClipVertex){-256,256,1,3};
    int count=4;
    for (int line=4;line<4+n && count>=3;line++) {
        ClipVertex[32] next=zeroed; int used=0;
        for (int i=0;i<count;i++) {
            ClipVertex s=polygon[(i+count-1)%count], e=polygon[i], crossing=zeroed;
            bool inside_s=clip_side(lines[line],s)<=0, inside_e=clip_side(lines[line],e)<=0;
            if (inside_s!=inside_e) {
                if (!clip_intersect(lines[e.incoming],lines[line],&crossing)) return -1;
                crossing.incoming=inside_s ? e.incoming : line;
                clip_append(&next[0],&used,crossing);
            }
            if (inside_e) clip_append(&next[0],&used,e);
        }
        if (used>1 && clip_same(next[0],next[used-1])) { next[0].incoming=next[used-1].incoming; used--; }
        count=used;
        for (int i=0;i<count;i++) polygon[i]=next[i];
        bool noncollinear=false;
        for (int i=0;i<count && count>=3;i++)
            if (clip_turn(polygon[i],polygon[(i+1)%count],polygon[(i+2)%count])!=0) noncollinear=true;
        if (!noncollinear) count=0;
    }
    bool changed=true;
    while (changed && count>=3) {
        changed=false;
        for (int i=0;i<count;i++) {
            if (clip_turn(polygon[(i+count-1)%count],polygon[i],polygon[(i+1)%count])==0) {
                for (int j=i;j+1<count;j++) polygon[j]=polygon[j+1];
                count--; changed=true; break;
            }
        }
    }
    if (count<3) count=0;
    int first=0;
    for (int i=1;i<count;i++) {
        long yi=polygon[i].y*polygon[first].den, yf=polygon[first].y*polygon[i].den;
        if (yi<yf || (yi==yf && polygon[i].x*polygon[first].den<polygon[first].x*polygon[i].den)) first=i;
    }
    usz needed=(usz)(1+4*count)*8;
    if (output==null || capacity<needed) return -2;
    usz offset=0; clip_put(output,&offset,count);
    for (int i=0;i<count;i++) {
        ClipVertex p=polygon[(first+i)%count];
        long gx=clip_gcd(p.x,p.den), gy=clip_gcd(p.y,p.den);
        clip_put(output,&offset,p.x/gx); clip_put(output,&offset,p.den/gx);
        clip_put(output,&offset,p.y/gy); clip_put(output,&offset,p.den/gy);
    }
    return (long)needed;
}
