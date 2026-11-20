module k_quadtree_edge_distribution;

const int MAX_E=8; const int MAX_C=46; const int DEPTH=4; const usz MAX_WORDS=127;
struct Cell { int depth; int prefix; int lo; int alt_lo; int x0; int y0; int x1; int y1; int endpoints; }
struct Edge { int x0; int y0; int x1; int y1; int start; int end; bool negative; }
struct Point { int x; int y; }
struct Exit { int edge; int side; long num; long den; }

fn long orient(Point a,Point b,Point c){return (long)(b.x-a.x)*(c.y-a.y)-(long)(b.y-a.y)*(c.x-a.x);}
fn bool on_segment(Point a,Point b,Point p){return p.x>=min(a.x,b.x)&&p.x<=max(a.x,b.x)&&p.y>=min(a.y,b.y)&&p.y<=max(a.y,b.y);}
fn bool intersects(Point a,Point b,Point c,Point d){
    long o1=orient(a,b,c),o2=orient(a,b,d),o3=orient(c,d,a),o4=orient(c,d,b);
    if(o1==0&&on_segment(a,b,c)||o2==0&&on_segment(a,b,d)||o3==0&&on_segment(c,d,a)||o4==0&&on_segment(c,d,b))return true;
    return o1*o2<0&&o3*o4<0;
}
fn int positive_key(int x,int y){int key=0;for(int bit=7;bit>=4;bit--)key=(key<<2)|(((x>>bit)&1)<<1)|((y>>bit)&1);return key;}
fn int remap(int q){int[4] map={2,0,3,1};return map[q];}
fn int alt_prefix(int depth,int prefix){int result=0;for(int shift=2*(depth-1);shift>=0;shift-=2)result=(result<<2)|remap((prefix>>shift)&3);return result;}
fn void make_box(Cell* c){int x=0,y=0;for(int shift=2*(c->depth-1);shift>=0;shift-=2){int q=(c->prefix>>shift)&3;x=(x<<1)|(q>>1);y=(y<<1)|(q&1);}int side=256>>c->depth;c->x0=x*side;c->y0=y*side;c->x1=c->x0+side;c->y1=c->y0+side;}
fn int find_cell(Cell* cells,int c,int key){for(int i=0;i<c;i++){int span=1<<(2*(DEPTH-cells[i].depth));if(key>=cells[i].lo&&key<cells[i].lo+span)return i;}return -1;}
fn void sweep_box(Cell* c,bool rotated,int* x0,int* y0,int* x1,int* y1){if(rotated){*x0=256-c->y1;*y0=c->x0;*x1=256-c->y0;*y1=c->x1;}else{*x0=c->x0;*y0=c->y0;*x1=c->x1;*y1=c->y1;}}
fn void sweep_edge(Edge* e,bool rotated,Point* a,Point* b){if(rotated){*a=Point{256-e->y0,e->x0};*b=Point{256-e->y1,e->x1};}else{*a=Point{e->x0,e->y0};*b=Point{e->x1,e->y1};}}
fn bool segment_box(Edge* e,Cell* c,bool rotated){int x0,y0,x1,y1;Point a,b;sweep_box(c,rotated,&x0,&y0,&x1,&y1);sweep_edge(e,rotated,&a,&b);if(a.x>=x0&&a.x<=x1&&a.y>=y0&&a.y<=y1||b.x>=x0&&b.x<=x1&&b.y>=y0&&b.y<=y1)return true;Point[4] corners={Point{x0,y0},Point{x1,y0},Point{x1,y1},Point{x0,y1}};for(int i=0;i<4;i++)if(intersects(a,b,corners[i],corners[(i+1)&3]))return true;return false;}
fn bool append_point(Point* path,int* n,Point p){if(*n>0&&path[*n-1].x==p.x&&path[*n-1].y==p.y)return true;if(*n>=33)return false;path[*n]=p;*n=*n+1;return true;}
fn bool build_frontier(Cell* cells,int c,int* order,int cut,bool rotated,Point* path,int* path_n,int* corner){
    int[256] atom_cell;for(int i=0;i<256;i++)atom_cell[i]=-1;
    int[46] rank;for(int i=0;i<c;i++)rank[order[i]]=i;
    for(int pos=0;pos<c;pos++){int id=order[pos],start=rotated?cells[id].alt_lo:cells[id].lo;int span=1<<(2*(DEPTH-cells[id].depth));for(int k=start;k<start+span;k++)atom_cell[k]=id;}
    bool[16][16] processed={};
    for(int key=0;key<256;key++){int id=atom_cell[key];if(id<0)return false;int x=0,y=0;for(int shift=6;shift>=0;shift-=2){int q=(key>>shift)&3;x=(x<<1)|(q>>1);y=(y<<1)|(q&1);}processed[x][y]=rank[id]<cut;}
    int[16] h;for(int x=0;x<16;x++){int v=0;while(v<16&&processed[x][v])v++;for(int y=0;y<16;y++)if(processed[x][y]!=(y<v))return false;h[x]=v;if(x>0&&h[x-1]<v)return false;}
    *path_n=0;if(!append_point(path,path_n,Point{0,256}))return false;
    for(int y=15;y>=h[0];y--)if(!append_point(path,path_n,Point{0,y*16}))return false;
    for(int x=0;x<16;x++){if(!append_point(path,path_n,Point{(x+1)*16,h[x]*16}))return false;int next=x<15?h[x+1]:0;for(int y=h[x]-1;y>=next;y--)if(!append_point(path,path_n,Point{(x+1)*16,y*16}))return false;}
    if(path[0].x!=0||path[0].y!=256||path[*path_n-1].x!=256||path[*path_n-1].y!=0)return false;
    int x0,y0,x1,y1;sweep_box(&cells[order[cut]],rotated,&x0,&y0,&x1,&y1);for(int i=0;i<*path_n;i++)if(path[i].x==x0&&path[i].y==y0){*corner=i;return true;}return false;
}
fn int frontier_segment(Point a,Point b,Point* path,int n){int found=-1;for(int i=0;i<n-1;i++)if(intersects(a,b,path[i],path[i+1])){if(found>=0)return -2;found=i;}return found;}
fn bool exit_for_cell(Point a,Point b,int x0,int y0,int x1,int y1,Exit* out,int id){long dx=b.x-a.x,dy=b.y-a.y;int found=0;if(dy>0){long ydist=y1-a.y,num=(long)a.x*dy+ydist*dx;if(ydist>0&&ydist<dy&&(long)x0*dy<num&&num<(long)x1*dy){*out=Exit{id,0,num,dy};found++;}}if(dx>0){long xdist=x1-a.x,num=(long)a.y*dx+xdist*dy;if(xdist>0&&xdist<dx&&(long)y0*dx<num&&num<(long)y1*dx){*out=Exit{id,1,num,dx};found++;}}return found==1;}
fn bool exit_less(Exit a,Exit b){long l=a.num*b.den,r=b.num*a.den;return l<r||(l==r&&a.edge<b.edge);}
fn bool run_sweep(Cell* cells,int c,Edge* edges,int n,int[8][2] endpoints,bool rotated,ulong* masks){
    int[46] order;for(int i=0;i<c;i++)order[i]=i;
    if(rotated)for(int i=1;i<c;i++){int v=order[i],j=i;while(j>0&&(cells[order[j-1]].alt_lo>cells[v].alt_lo||(cells[order[j-1]].alt_lo==cells[v].alt_lo&&order[j-1]>v))){order[j]=order[j-1];j--;}order[j]=v;}
    Point[8] ea,eb;int[8] ids,keys;int m=0;for(int id=0;id<n;id++)if(edges[id].negative==rotated){sweep_edge(&edges[id],rotated,&ea[id],&eb[id]);int key=positive_key(ea[id].x,ea[id].y),j=m++;while(j>0&&(keys[j-1]>key||(keys[j-1]==key&&ids[j-1]>id))){keys[j]=keys[j-1];ids[j]=ids[j-1];j--;}keys[j]=key;ids[j]=id;}
    int[8] sl,sb;int sln=0,sbn=0;
    for(int pos=0;pos<c;pos++){int cid=order[pos],x0,y0,x1,y1;sweep_box(&cells[cid],rotated,&x0,&y0,&x1,&y1);int[16] candidates;int cn=0;
        while(sln>0&&segment_box(&edges[sl[sln-1]],&cells[cid],rotated)){sln--;candidates[cn++]=sl[sln];}
        while(sbn>0&&segment_box(&edges[sb[sbn-1]],&cells[cid],rotated)){sbn--;candidates[cn++]=sb[sbn];}
        for(int q=0;q<m;q++){int id=ids[q];if(endpoints[id][0]==cid)candidates[cn++]=id;}
        Exit[16] exits;int en=0;for(int q=0;q<cn;q++){int id=candidates[q];masks[cid]|=(ulong)1<<id;if(endpoints[id][1]==cid)continue;if(!exit_for_cell(ea[id],eb[id],x0,y0,x1,y1,&exits[en],id))return false;en++;}
        for(int i=1;i<en;i++){Exit v=exits[i];int j=i;while(j>0&&(exits[j-1].side>v.side||(exits[j-1].side==v.side&&exit_less(v,exits[j-1])))){exits[j]=exits[j-1];j--;}exits[j]=v;}
        for(int i=0;i<en;i++)if(exits[i].side==0){if(sln>=8)return false;sl[sln++]=exits[i].edge;}else{if(sbn>=8)return false;sb[sbn++]=exits[i].edge;}
        if(pos+1==c)continue;Point[33] path;int pn=0,corner=0;if(!build_frontier(cells,c,&order[0],pos+1,rotated,&path[0],&pn,&corner))return false;
        int nx0,ny0,nx1,ny1;sweep_box(&cells[order[pos+1]],rotated,&nx0,&ny0,&nx1,&ny1);
        if(ny0>y0){while(sln>0){int id=sl[sln-1],where=frontier_segment(ea[id],eb[id],&path[0],pn);if(where<0)return false;if(where<corner)break;if(sbn>=8)return false;sb[sbn++]=sl[--sln];}}
        else{while(sbn>0){int id=sb[sbn-1],where=frontier_segment(ea[id],eb[id],&path[0],pn);if(where<0)return false;if(where>=corner)break;if(sln>=8)return false;sl[sln++]=sb[--sbn];}}
    }
    return sln==0&&sbn==0;
}
fn void put_i64(char* out,usz at,long value){ulong bits=(ulong)value;for(usz i=0;i<8;i++)out[at+i]=(char)(bits>>(8*i));}

fn long k_quadtree_edge_distribution(long* input,usz length,char* output,usz capacity) @export("k_quadtree_edge_distribution") {
    if(input==null||length<2||length>MAX_WORDS)return -1;long nv=input[0],cv=input[1];if(nv<0||nv>MAX_E||cv<1||cv>MAX_C)return -1;int n=(int)nv,c=(int)cv;if(length!=2+2*(usz)c+4*(usz)n)return -1;
    Cell[46] cells={};Edge[8] edges={};int[8][2] endpoints={};usz at=2;int previous=0;
    for(int i=0;i<c;i++){long d=input[at++],p=input[at++];if(d<0||d>DEPTH||p<0||p>=(1L<<(2*d)))return -1;cells[i].depth=(int)d;cells[i].prefix=(int)p;int span=1<<(2*(DEPTH-cells[i].depth));cells[i].lo=cells[i].prefix*span;if(cells[i].lo!=previous)return -1;previous=cells[i].lo+span;make_box(&cells[i]);}
    if(previous!=256||(n==0&&(c!=1||cells[0].depth!=0||cells[0].prefix!=0)))return -1;
    for(int i=0;i<c;i++)cells[i].alt_lo=alt_prefix(cells[i].depth,cells[i].prefix)<<(2*(DEPTH-cells[i].depth));
    Point[16] pts;
    for(int i=0;i<n;i++){long x0=input[at],y0=input[at+1],x1=input[at+2],y1=input[at+3];at+=4;if(x0<0||x0>255||y0<0||y0>255||x1<0||x1>255||y1<0||y1>255||x0%16==0||y0%16==0||x1%16==0||y1%16==0)return -1;if(x0==x1&&y0==y1||y0==y1)return -1;if(x0>x1||(x0==x1&&y0>y1)){long tx=x0,ty=y0;x0=x1;y0=y1;x1=tx;y1=ty;}if(x0==x1&&y1<=y0)return -1;edges[i]=Edge{(int)x0,(int)y0,(int)x1,(int)y1,-1,-1,y1<y0};pts[2*i]=Point{(int)x0,(int)y0};pts[2*i+1]=Point{(int)x1,(int)y1};
        for(int gx=0;gx<=256;gx+=16)for(int gy=0;gy<=256;gy+=16){Point p=Point{gx,gy};if(orient(pts[2*i],pts[2*i+1],p)==0&&on_segment(pts[2*i],pts[2*i+1],p))return -1;}
        for(int j=0;j<2*i;j++)if(pts[j].x==(int)x0&&pts[j].y==(int)y0)return -1;for(int j=0;j<2*i+1;j++)if(pts[j].x==(int)x1&&pts[j].y==(int)y1)return -1;for(int j=0;j<i;j++)if(intersects(pts[2*i],pts[2*i+1],pts[2*j],pts[2*j+1]))return -1;
        int a=find_cell(&cells[0],c,positive_key((int)x0,(int)y0)),b=find_cell(&cells[0],c,positive_key((int)x1,(int)y1));if(a<0||b<0)return -1;endpoints[i][0]=a;endpoints[i][1]=b;edges[i].start=a;edges[i].end=b;cells[a].endpoints++;cells[b].endpoints++;
    }
    for(int i=0;i<c;i++)if(cells[i].endpoints>1)return -1;
    int[85] pd,pp;int pc=0;for(int i=0;i<c;i++)for(int d=0;d<cells[i].depth;d++){int p=cells[i].prefix>>(2*(cells[i].depth-d));bool found=false;for(int q=0;q<pc;q++)if(pd[q]==d&&pp[q]==p)found=true;if(!found){pd[pc]=d;pp[pc++]=p;}}
    for(int q=0;q<pc;q++){uint occupied=0;for(int i=0;i<c;i++){if(cells[i].endpoints==0||cells[i].depth<=pd[q])continue;if((cells[i].prefix>>(2*(cells[i].depth-pd[q])))==pp[q])occupied|=1u<<((cells[i].prefix>>(2*(cells[i].depth-pd[q]-1)))&3);}if(occupied==0||(occupied&(occupied-1))==0)return -1;}
    for(int i=0;i<n;i++)for(int dir=0;dir<2;dir++){if(edges[i].negative!=(dir!=0))continue;int[46] order;for(int j=0;j<c;j++)order[j]=j;if(dir!=0)for(int a=1;a<c;a++){int v=order[a],j=a;while(j>0&&cells[order[j-1]].alt_lo>cells[v].alt_lo){order[j]=order[j-1];j--;}order[j]=v;}int rs=0,re=0;for(int j=0;j<c;j++){if(order[j]==endpoints[i][0])rs=j;if(order[j]==endpoints[i][1])re=j;}if(rs>re)return -1;}
    ulong[46] masks={};if(!run_sweep(&cells[0],c,&edges[0],n,endpoints,false,&masks[0])||!run_sweep(&cells[0],c,&edges[0],n,endpoints,true,&masks[0]))return -1;
    usz bytes=8*(1+(usz)c);if(output==null||capacity<bytes)return -2;put_i64(output,0,c);for(int i=0;i<c;i++)put_i64(output,8*(usz)(i+1),(long)masks[i]);return (long)bytes;
}
