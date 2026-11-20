module weiler_atherton_polygon_intersection;

const MAX_V = 6;
const MAX_X = 36;
const MAX_NODE = 42;
const MAX_WORDS = 210;

struct Rat { long n; long d; }
struct Point { long xn; long xd; long yn; long yd; }
struct Crossing {
    Point p; Rat ta; Rat tb; bool ae; bool ax; bool be; bool bx;
}
struct Node { Point p; int cross; }
struct Ring { Point[48] p; int count; }

fn long abs64(long x) { return x < 0 ? -x : x; }
fn long gcd64(long a, long b) {
    a=abs64(a); b=abs64(b);
    while(b!=0) { long r=a%b; a=b; b=r; }
    return a==0 ? 1 : a;
}
fn Rat make_rat(long n,long d) {
    if(d<0) { n=-n; d=-d; }
    long g=gcd64(n,d); Rat r={n/g,d/g}; return r;
}
fn bool less_rat(Rat a,Rat b) { return a.n*b.d < b.n*a.d; }
fn bool equal_rat(Rat a,Rat b) { return a.n==b.n && a.d==b.d; }
fn bool less_point(Point a,Point b) {
    if(!equal_rat(make_rat(a.xn,a.xd),make_rat(b.xn,b.xd))) return a.xn*b.xd < b.xn*a.xd;
    return a.yn*b.yd < b.yn*a.yd;
}
fn bool equal_point(Point a,Point b) {
    return a.xn==b.xn && a.xd==b.xd && a.yn==b.yn && a.yd==b.yd;
}
fn long orient(long ax,long ay,long bx,long by,long cx,long cy) {
    return (bx-ax)*(cy-ay)-(by-ay)*(cx-ax);
}
fn bool on_segment(long ax,long ay,long bx,long by,long px,long py) {
    return orient(ax,ay,bx,by,px,py)==0 && px>=min(ax,bx) && px<=max(ax,bx)
        && py>=min(ay,by) && py<=max(ay,by);
}
fn int relation(long ax,long ay,long bx,long by,long cx,long cy,long dx,long dy) {
    long o1=orient(ax,ay,bx,by,cx,cy),o2=orient(ax,ay,bx,by,dx,dy);
    long o3=orient(cx,cy,dx,dy,ax,ay),o4=orient(cx,cy,dx,dy,bx,by);
    if(((o1>0&&o2<0)||(o1<0&&o2>0))&&((o3>0&&o4<0)||(o3<0&&o4>0))) return 1;
    if((o1==0&&on_segment(ax,ay,bx,by,cx,cy))||(o2==0&&on_segment(ax,ay,bx,by,dx,dy))
        ||(o3==0&&on_segment(cx,cy,dx,dy,ax,ay))||(o4==0&&on_segment(cx,cy,dx,dy,bx,by))) return 2;
    return 0;
}
fn bool polygon_valid(long* p,int n) {
    long area=0;
    for(int i=0;i<n;i++) {
        int prev=(i+n-1)%n,next=(i+1)%n;
        long x=p[2*i],y=p[2*i+1],nx=p[2*next],ny=p[2*next+1];
        area+=x*ny-y*nx;
        if(orient(p[2*prev],p[2*prev+1],x,y,nx,ny)==0) return false;
        for(int j=0;j<i;j++) if(x==p[2*j]&&y==p[2*j+1]) return false;
    }
    if(area<=0) return false;
    for(int i=0;i<n;i++) for(int j=i+1;j<n;j++) {
        if(j==i+1||(i==0&&j==n-1)) continue;
        int k=(i+1)%n,l=(j+1)%n;
        if(relation(p[2*i],p[2*i+1],p[2*k],p[2*k+1],p[2*j],p[2*j+1],p[2*l],p[2*l+1])!=0) return false;
    }
    return true;
}
fn bool inside(long x,long y,long* p,int n) {
    int winding=0;
    for(int i=0;i<n;i++) {
        int j=(i+1)%n;
        long side=orient(p[2*i],p[2*i+1],p[2*j],p[2*j+1],x,y);
        if(p[2*i+1]<=y&&y<p[2*j+1]&&side>0) winding++;
        else if(p[2*j+1]<=y&&y<p[2*i+1]&&side<0) winding--;
    }
    return winding!=0;
}
fn Point intersection(long ax,long ay,long bx,long by,long cx,long cy,long dx,long dy,Rat* ta,Rat* tb) {
    long rx=bx-ax,ry=by-ay,sx=dx-cx,sy=dy-cy;
    long den=rx*sy-ry*sx,tn=(cx-ax)*sy-(cy-ay)*sx,un=(cx-ax)*ry-(cy-ay)*rx;
    if(den<0) { den=-den; tn=-tn; un=-un; }
    *ta=make_rat(tn,den); *tb=make_rat(un,den);
    Rat xx=make_rat(ax*den+rx*tn,den), yy=make_rat(ay*den+ry*tn,den);
    Point p={xx.n,xx.d,yy.n,yy.d}; return p;
}
fn Point int_point(long x,long y) { Point p={x,1,y,1}; return p; }
fn void store_i64_le(char* out,usz off,long value) {
    ulong bits=(ulong)value;
    for(usz i=0;i<8;i++) { out[off+i]=(char)(bits&255); bits>>=8; }
}

fn long weiler_atherton_polygon_intersection(long* input,usz length,char* output,usz capacity)
    @export("weiler_atherton_polygon_intersection") {
    if(input==null||length<2||length>27) return -1;
    long na64=input[0],nb64=input[1];
    if(na64<3||na64>MAX_V||nb64<3||nb64>MAX_V||length!=(usz)(2+2*na64+2*nb64)) return -1;
    int na=(int)na64,nb=(int)nb64;
    long[12] a=zeroed,b=zeroed; usz cursor=2;
    for(int i=0;i<2*na;i++) { long v=input[cursor++]; if(v< -16||v>16)return -1; a[i]=v; }
    for(int i=0;i<2*nb;i++) { long v=input[cursor++]; if(v< -16||v>16)return -1; b[i]=v; }
    if(!polygon_valid(&a[0],na)||!polygon_valid(&b[0],nb)) return -1;

    Crossing[MAX_X] cross=zeroed; int cross_count=0;
    int[MAX_V][MAX_V] ev_a=zeroed,ev_b=zeroed; int[MAX_V] cnt_a=zeroed,cnt_b=zeroed;
    for(int i=0;i<na;i++) for(int j=0;j<nb;j++) {
        int ni=(i+1)%na,nj=(j+1)%nb;
        int rel=relation(a[2*i],a[2*i+1],a[2*ni],a[2*ni+1],b[2*j],b[2*j+1],b[2*nj],b[2*nj+1]);
        if(rel==2) return -1;
        if(rel==1) {
            Crossing* c=&cross[cross_count];
            c.p=intersection(a[2*i],a[2*i+1],a[2*ni],a[2*ni+1],b[2*j],b[2*j+1],b[2*nj],b[2*nj+1],&c.ta,&c.tb);
            long ab=orient(b[2*j],b[2*j+1],b[2*nj],b[2*nj+1],a[2*i],a[2*i+1]);
            long aa=orient(b[2*j],b[2*j+1],b[2*nj],b[2*nj+1],a[2*ni],a[2*ni+1]);
            long bb=orient(a[2*i],a[2*i+1],a[2*ni],a[2*ni+1],b[2*j],b[2*j+1]);
            long ba=orient(a[2*i],a[2*i+1],a[2*ni],a[2*ni+1],b[2*nj],b[2*nj+1]);
            c.ae=ab<0&&aa>0;c.ax=ab>0&&aa<0;c.be=bb<0&&ba>0;c.bx=bb>0&&ba<0;
            if((!c.ae&&!c.ax)||(!c.be&&!c.bx)||c.ae==c.be)return -1;
            ev_a[i][cnt_a[i]++]=cross_count;ev_b[j][cnt_b[j]++]=cross_count;cross_count++;
        }
    }

    Ring[16] rings=zeroed; int ring_count=0;
    if(cross_count==0) {
        if(inside(a[0],a[1],&b[0],nb)) {
            rings[0].count=na;for(int i=0;i<na;i++)rings[0].p[i]=int_point(a[2*i],a[2*i+1]);ring_count=1;
        } else if(inside(b[0],b[1],&a[0],na)) {
            rings[0].count=nb;for(int i=0;i<nb;i++)rings[0].p[i]=int_point(b[2*i],b[2*i+1]);ring_count=1;
        }
    } else {
        Node[MAX_NODE] nodes_a=zeroed,nodes_b=zeroed;int ca=0,cb=0;
        int[MAX_X] pos_a=zeroed,pos_b=zeroed;
        for(int e=0;e<na;e++) {
            nodes_a[ca].p=int_point(a[2*e],a[2*e+1]);nodes_a[ca].cross=-1;ca++;
            for(int z=1;z<cnt_a[e];z++){int id=ev_a[e][z],k=z-1;while(k>=0&&less_rat(cross[id].ta,cross[ev_a[e][k]].ta)){ev_a[e][k+1]=ev_a[e][k];k--;}ev_a[e][k+1]=id;}
            for(int z=0;z<cnt_a[e];z++){int id=ev_a[e][z];nodes_a[ca].p=cross[id].p;nodes_a[ca].cross=id;pos_a[id]=ca++;}
        }
        for(int e=0;e<nb;e++) {
            nodes_b[cb].p=int_point(b[2*e],b[2*e+1]);nodes_b[cb].cross=-1;cb++;
            for(int z=1;z<cnt_b[e];z++){int id=ev_b[e][z],k=z-1;while(k>=0&&less_rat(cross[id].tb,cross[ev_b[e][k]].tb)){ev_b[e][k+1]=ev_b[e][k];k--;}ev_b[e][k+1]=id;}
            for(int z=0;z<cnt_b[e];z++){int id=ev_b[e][z];nodes_b[cb].p=cross[id].p;nodes_b[cb].cross=id;pos_b[id]=cb++;}
        }
        bool[MAX_X] visited=zeroed;
        for(int start=0;start<ca;start++) {
            int sid=nodes_a[start].cross;if(sid<0||!cross[sid].ae||visited[sid])continue;
            if(ring_count>=16)return -1;
            Ring* r=&rings[ring_count];r.p[r.count++]=nodes_a[start].p;visited[sid]=true;
            bool active_a=true;int index=start,guard=0;
            while(true) {
                if(++guard>2*cross_count+na+nb+1)return -1;
                Node* nodes=active_a?&nodes_a[0]:&nodes_b[0];int count=active_a?ca:cb;
                int next=(index+1)%count;Node node=nodes[next];
                if(node.cross>=0) {
                    int id=node.cross;visited[id]=true;bool exits=active_a?cross[id].ax:cross[id].bx;
                    if(active_a&&id==sid)break;
                    if(exits) {
                        if(id==sid)break;
                        active_a=!active_a;index=active_a?pos_a[id]:pos_b[id];continue;
                    }
                }
                if(r.count>=48)return -1;r.p[r.count++]=node.p;
                index=next;
            }
            if(r.count<3)return -1;ring_count++;
        }
        for(int i=0;i<cross_count;i++)if(!visited[i])return -1;
    }

    for(int r=0;r<ring_count;r++) {
        int pivot=0;for(int i=1;i<rings[r].count;i++)if(less_point(rings[r].p[i],rings[r].p[pivot]))pivot=i;
        if(pivot>0){Point[48] temp=zeroed;for(int i=0;i<rings[r].count;i++)temp[i]=rings[r].p[(pivot+i)%rings[r].count];for(int i=0;i<rings[r].count;i++)rings[r].p[i]=temp[i];}
    }
    for(int i=1;i<ring_count;i++){Ring key=rings[i];int j=i-1;while(j>=0&&less_point(key.p[0],rings[j].p[0])){rings[j+1]=rings[j];j--;}rings[j+1]=key;}
    long[MAX_WORDS] staged=zeroed;int words=0;staged[words++]=ring_count;
    for(int r=0;r<ring_count;r++){staged[words++]=rings[r].count;for(int i=0;i<rings[r].count;i++){Point p=rings[r].p[i];staged[words++]=p.xn;staged[words++]=p.xd;staged[words++]=p.yn;staged[words++]=p.yd;}}
    usz bytes=(usz)words*8;if(bytes>1680)return -1;if(output==null||capacity<bytes)return -2;
    for(int i=0;i<words;i++)store_i64_le(output,(usz)i*8,staged[i]);return (long)bytes;
}
