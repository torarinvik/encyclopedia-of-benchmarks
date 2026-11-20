module pmr_edge_quadtree;

const int MAX_SEGMENTS = 8, MAX_DEPTH = 8, MAX_NODES = 2048, MAX_INPUT = 35;
struct Node { int parent, quadrant, depth; int xmin, ymin, xmax, ymax; int[4] child; int count; int[MAX_SEGMENTS] ids; }
struct State { Node[MAX_NODES] nodes; int used; int[MAX_SEGMENTS * 4] segments; }

fn long orient(long ax, long ay, long bx, long by, long cx, long cy) {
    return (bx-ax)*(cy-ay) - (by-ay)*(cx-ax);
}
fn bool between(long a, long b, long p) { return (a <= p && p <= b) || (b <= p && p <= a); }
fn bool on_segment(long ax,long ay,long bx,long by,long px,long py) {
    return between(ax,bx,px) && between(ay,by,py);
}
fn bool seg_intersects(long ax,long ay,long bx,long by,long cx,long cy,long dx,long dy) {
    long o1=orient(ax,ay,bx,by,cx,cy), o2=orient(ax,ay,bx,by,dx,dy);
    long o3=orient(cx,cy,dx,dy,ax,ay), o4=orient(cx,cy,dx,dy,bx,by);
    if (((o1<0&&o2>0)||(o1>0&&o2<0)) && ((o3<0&&o4>0)||(o3>0&&o4<0))) return true;
    return (o1==0&&on_segment(ax,ay,bx,by,cx,cy)) || (o2==0&&on_segment(ax,ay,bx,by,dx,dy)) ||
           (o3==0&&on_segment(cx,cy,dx,dy,ax,ay)) || (o4==0&&on_segment(cx,cy,dx,dy,bx,by));
}
fn bool intersects_box(State* s, int sid, Node* cell) {
    int base=sid*4; long x0=2*(long)s.segments[base], y0=2*(long)s.segments[base+1];
    long x1=2*(long)s.segments[base+2], y1=2*(long)s.segments[base+3];
    long lx=cell.xmin,ly=cell.ymin,hx=cell.xmax,hy=cell.ymax;
    if ((lx<=x0&&x0<=hx&&ly<=y0&&y0<=hy)||(lx<=x1&&x1<=hx&&ly<=y1&&y1<=hy)) return true;
    return seg_intersects(x0,y0,x1,y1,lx,ly,hx,ly)||seg_intersects(x0,y0,x1,y1,hx,ly,hx,hy)||
           seg_intersects(x0,y0,x1,y1,hx,hy,lx,hy)||seg_intersects(x0,y0,x1,y1,lx,hy,lx,ly);
}
fn void init_node(State* s,int id,int parent,int q,int depth,int xmin,int ymin,int xmax,int ymax) {
    s.nodes[id].parent=parent;s.nodes[id].quadrant=q;s.nodes[id].depth=depth;
    s.nodes[id].xmin=xmin;s.nodes[id].ymin=ymin;s.nodes[id].xmax=xmax;s.nodes[id].ymax=ymax;s.nodes[id].count=0;
    for(int k=0;k<4;k++)s.nodes[id].child[k]=-1;
}
fn bool insert(State* s,int id,int sid,int threshold) {
    if(s.nodes[id].child[0]>=0){for(int q=0;q<4;q++){int child=s.nodes[id].child[q];if(intersects_box(s,sid,&s.nodes[child])&&!insert(s,child,sid,threshold))return false;}return true;}
    int used=s.nodes[id].count;if(used>=MAX_SEGMENTS)return false;s.nodes[id].ids[used]=sid;s.nodes[id].count++;
    if(s.nodes[id].count<=threshold)return true;
    if(s.nodes[id].depth>=MAX_DEPTH||s.used+4>MAX_NODES)return false;
    int[MAX_SEGMENTS] previous=s.nodes[id].ids;int previous_count=s.nodes[id].count;
    int xmin=s.nodes[id].xmin,ymin=s.nodes[id].ymin,xmax=s.nodes[id].xmax,ymax=s.nodes[id].ymax;
    int mx=xmin+(xmax-xmin)/2,my=ymin+(ymax-ymin)/2,base=s.used,depth=s.nodes[id].depth+1;
    for(int q=0;q<4;q++){int x0=q%2==0?xmin:mx,x1=q%2==0?mx:xmax;int y0=q<2?my:ymin,y1=q<2?ymax:my;init_node(s,base+q,id,q,depth,x0,y0,x1,y1);}
    s.used+=4;s.nodes[id].count=0;for(int q=0;q<4;q++)s.nodes[id].child[q]=base+q;
    for(int i=0;i<previous_count;i++)for(int q=0;q<4;q++){int child=base+q;if(intersects_box(s,previous[i],&s.nodes[child])&&!insert(s,child,previous[i],threshold))return false;}
    return true;
}
fn void preorder(State* s,int id,int* order,int* count){order[count[0]]=id;count[0]++;if(s.nodes[id].child[0]>=0)for(int q=0;q<4;q++)preorder(s,s.nodes[id].child[q],order,count);}
fn void store_le(char* output,usz offset,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++){output[offset+b]=(char)(bits&255ul);bits>>=8;}}

fn long pmr_edge_quadtree(long* input,usz length,char* output,usz capacity) @export("pmr_edge_quadtree") {
    if(input==null||length<2||length>MAX_INPUT)return -1;
    if(input[0]<0||input[0]>MAX_SEGMENTS||input[1]<1||input[1]>MAX_SEGMENTS)return -1;
    int count=(int)input[0],threshold=(int)input[1];if(length!=(usz)(2+4*count))return -1;
    State s=zeroed;s.used=1;
    for(int sid=0;sid<count;sid++){for(int k=0;k<4;k++){long value=input[2+sid*4+k];if(value<0||value>255)return -1;s.segments[sid*4+k]=(int)value;}
        if(s.segments[sid*4]==s.segments[sid*4+2]&&s.segments[sid*4+1]==s.segments[sid*4+3])return -1;}
    init_node(&s,0,-1,-1,0,-1,-1,511,511);for(int sid=0;sid<count;sid++)if(!insert(&s,0,sid,threshold))return -1;
    int[MAX_NODES] order,remap;int count_nodes=0;preorder(&s,0,&order[0],&count_nodes);
    usz bytes=16;for(int i=0;i<count_nodes;i++)bytes+=32+(usz)s.nodes[order[i]].count*8;
    if(output==null||capacity<bytes)return -2;
    for(int i=0;i<count_nodes;i++)remap[order[i]]=i;
    store_le(output,0,count_nodes);store_le(output,8,count);usz cursor=16;
    for(int i=0;i<count_nodes;i++){Node* node=&s.nodes[order[i]];store_le(output,cursor,node.parent<0?-1:remap[node.parent]);cursor+=8;
        store_le(output,cursor,node.quadrant);cursor+=8;store_le(output,cursor,node.depth);cursor+=8;store_le(output,cursor,node.count);cursor+=8;
        for(int j=0;j<node.count;j++){store_le(output,cursor,node.ids[j]);cursor+=8;}}
    return (long)bytes;
}
