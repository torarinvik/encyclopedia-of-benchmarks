#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum {
    MAX_EDGES = 8,
    MAX_CELLS = 46,
    MAX_DEPTH = 4,
    MAX_WORDS = 127,
    MAX_OUTPUT_BYTES = 376,
    INVALID_INPUT = -1,
    OUTPUT_ERROR = -2
};

typedef struct {
    int32_t depth, prefix, lo, alt_lo;
    int32_t x0, y0, x1, y1;
    int32_t endpoint_count;
} Cell;

typedef struct {
    int32_t x0, y0, x1, y1;
    int32_t start_cell, end_cell;
    int32_t alternate;
} Edge;

typedef struct { int32_t x, y; } Point;

typedef struct {
    int32_t edge_id, side;
    int64_t numerator, denominator;
} Exit;

static int64_t orient(Point a, Point b, Point c) {
    return (int64_t)(b.x-a.x)*(c.y-a.y) - (int64_t)(b.y-a.y)*(c.x-a.x);
}

static bool on_segment(Point a, Point b, Point p) {
    return p.x >= (a.x < b.x ? a.x : b.x) && p.x <= (a.x > b.x ? a.x : b.x)
        && p.y >= (a.y < b.y ? a.y : b.y) && p.y <= (a.y > b.y ? a.y : b.y);
}

static bool segments_intersect(Point a, Point b, Point c, Point d) {
    int64_t o1 = orient(a,b,c), o2 = orient(a,b,d);
    int64_t o3 = orient(c,d,a), o4 = orient(c,d,b);
    if (o1 == 0 && on_segment(a,b,c)) return true;
    if (o2 == 0 && on_segment(a,b,d)) return true;
    if (o3 == 0 && on_segment(c,d,a)) return true;
    if (o4 == 0 && on_segment(c,d,b)) return true;
    return o1*o2 < 0 && o3*o4 < 0;
}

static bool segment_box(const Edge *e, const Cell *cell, bool alternate) {
    int32_t x0=cell->x0, y0=cell->y0, x1=cell->x1, y1=cell->y1;
    int32_t ax=e->x0, ay=e->y0, bx=e->x1, by=e->y1;
    if (alternate) {
        x0=256-cell->y1; y0=cell->x0; x1=256-cell->y0; y1=cell->x1;
        ax=256-e->y0; ay=e->x0; bx=256-e->y1; by=e->x1;
    }
    if (ax>=x0 && ax<=x1 && ay>=y0 && ay<=y1) return true;
    if (bx>=x0 && bx<=x1 && by>=y0 && by<=y1) return true;
    Point a={ax,ay}, b={bx,by};
    Point corners[4]={{x0,y0},{x1,y0},{x1,y1},{x0,y1}};
    for (int i=0;i<4;i++) if (segments_intersect(a,b,corners[i],corners[(i+1)&3])) return true;
    return false;
}

static int32_t positive_key(int32_t x, int32_t y) {
    int32_t key=0;
    for (int bit=7;bit>=4;--bit)
        key=(key<<2) | (((x>>bit)&1)<<1) | ((y>>bit)&1);
    return key;
}

static int32_t alternate_prefix(int32_t depth, int32_t prefix) {
    int32_t result=0;
    for (int shift=2*(depth-1);shift>=0;shift-=2) {
        int32_t digit=(prefix>>shift)&3;
        result=(result<<2) | ((int32_t[]){2,0,3,1})[digit];
    }
    return result;
}

static void cell_box(Cell *cell) {
    int32_t x=0,y=0;
    for (int shift=2*(cell->depth-1);shift>=0;shift-=2) {
        int32_t q=(cell->prefix>>shift)&3;
        x=(x<<1)|(q>>1); y=(y<<1)|(q&1);
    }
    int32_t side=256>>cell->depth;
    cell->x0=x*side; cell->y0=y*side;
    cell->x1=cell->x0+side; cell->y1=cell->y0+side;
}

static int32_t endpoint_cell(const Cell *cells, int32_t count, int32_t key) {
    for (int i=0;i<count;i++) {
        int32_t span=1 << (2*(MAX_DEPTH-cells[i].depth));
        if (key>=cells[i].lo && key<cells[i].lo+span) return i;
    }
    return -1;
}

static bool validate_partition(Cell *cells, int32_t c, int32_t n) {
    int32_t previous=0;
    for (int i=0;i<c;i++) {
        Cell *cell=&cells[i];
        if (cell->depth<0 || cell->depth>MAX_DEPTH || cell->prefix<0
            || cell->prefix >= (1 << (2*cell->depth))) return false;
        int32_t span=1 << (2*(MAX_DEPTH-cell->depth));
        cell->lo=cell->prefix*span;
        if (cell->lo!=previous) return false;
        previous=cell->lo+span;
        cell_box(cell);
    }
    if (previous!=256) return false;
    return n!=0 || (c==1 && cells[0].depth==0 && cells[0].prefix==0);
}

static bool point_inside_grid_vertex(Point a, Point b) {
    for (int x=0;x<=256;x+=16) for (int y=0;y<=256;y+=16) {
        Point p={x,y};
        if (orient(a,b,p)==0 && on_segment(a,b,p)) return true;
    }
    return false;
}

static bool validate_edges(const int64_t *input, size_t cursor, int32_t n,
                           Edge *edges, Cell *cells, int32_t c,
                           int32_t endpoint_cells[MAX_EDGES][2]) {
    Point endpoints[2*MAX_EDGES];
    for (int i=0;i<n;i++) {
        int64_t v[4]={input[cursor],input[cursor+1],input[cursor+2],input[cursor+3]};
        cursor+=4;
        for (int j=0;j<4;j++) if (v[j]<0 || v[j]>255 || v[j]%16==0) return false;
        int32_t x0=(int32_t)v[0],y0=(int32_t)v[1],x1=(int32_t)v[2],y1=(int32_t)v[3];
        if (x0==x1 && y0==y1) return false;
        if (y0==y1) return false;
        if (x0>x1 || (x0==x1 && y0>y1)) {
            int32_t tx=x0,ty=y0; x0=x1;y0=y1;x1=tx;y1=ty;
        }
        if ((x0==x1 && y1<=y0) || (x0!=x1 && x1<=x0)) return false;
        edges[i]=(Edge){x0,y0,x1,y1,-1,-1,y1<y0};
        endpoints[2*i]=(Point){x0,y0}; endpoints[2*i+1]=(Point){x1,y1};
        if (point_inside_grid_vertex(endpoints[2*i],endpoints[2*i+1])) return false;
        for (int j=0;j<2*i;j++)
            if (endpoints[j].x==x0 && endpoints[j].y==y0) return false;
        for (int j=0;j<2*i+1;j++)
            if (endpoints[j].x==x1 && endpoints[j].y==y1) return false;
        for (int j=0;j<i;j++)
            if (segments_intersect(endpoints[2*i],endpoints[2*i+1],endpoints[2*j],endpoints[2*j+1])) return false;
        int32_t a=endpoint_cell(cells,c,positive_key(x0,y0));
        int32_t b=endpoint_cell(cells,c,positive_key(x1,y1));
        if (a<0 || b<0) return false;
        endpoint_cells[i][0]=a; endpoint_cells[i][1]=b;
        edges[i].start_cell=a; edges[i].end_cell=b;
        cells[a].endpoint_count++; cells[b].endpoint_count++;
    }
    for (int i=0;i<c;i++) if (cells[i].endpoint_count>1) return false;

    int32_t parent_depth[85], parent_prefix[85], parent_count=0;
    for (int i=0;i<c;i++) for (int d=0;d<cells[i].depth;d++) {
        int32_t p=cells[i].prefix >> (2*(cells[i].depth-d));
        bool exists=false;
        for (int q=0;q<parent_count;q++) if (parent_depth[q]==d && parent_prefix[q]==p) exists=true;
        if (!exists && parent_count<85) { parent_depth[parent_count]=d;parent_prefix[parent_count++]=p; }
    }
    for (int q=0;q<parent_count;q++) {
        int32_t d=parent_depth[q],p=parent_prefix[q]; unsigned occupied=0;
        for (int i=0;i<c;i++) {
            Cell *cell=&cells[i];
            if (cell->endpoint_count==0 || cell->depth<=d) continue;
            if ((cell->prefix >> (2*(cell->depth-d)))==p) {
                int32_t child=(cell->prefix >> (2*(cell->depth-d-1)))&3;
                occupied|=1u<<child;
            }
        }
        if ((occupied&(occupied-1u))==0) return false;
    }
    return true;
}

static void sweep_box(const Cell *cell, bool alternate, int32_t *x0,int32_t *y0,int32_t *x1,int32_t *y1) {
    if (alternate) {
        *x0=256-cell->y1; *y0=cell->x0; *x1=256-cell->y0; *y1=cell->x1;
    } else { *x0=cell->x0;*y0=cell->y0;*x1=cell->x1;*y1=cell->y1; }
}

static void sweep_edge(const Edge *e, bool alternate, Point *a, Point *b) {
    if (alternate) { *a=(Point){256-e->y0,e->x0}; *b=(Point){256-e->y1,e->x1}; }
    else { *a=(Point){e->x0,e->y0}; *b=(Point){e->x1,e->y1}; }
}

static bool append_point(Point *path,int *count,Point p) {
    if (*count && path[*count-1].x==p.x && path[*count-1].y==p.y) return true;
    if (*count>=33) return false;
    path[(*count)++]=p; return true;
}

static bool build_frontier(const Cell *cells,int32_t c,const int32_t *order,int cut,
                           bool alternate,Point *path,int *path_count,int *corner_index) {
    int32_t atom_cell[256];
    for (int i=0;i<256;i++) atom_cell[i]=-1;
    for (int pos=0;pos<c;pos++) {
        int id=order[pos]; const Cell *cell=&cells[id];
        int start=alternate?cell->alt_lo:cell->lo;
        int span=1 << (2*(MAX_DEPTH-cell->depth));
        for (int k=start;k<start+span;k++) atom_cell[k]=id;
    }
    bool processed[16][16]={{false}}; int rank[46];
    for (int i=0;i<c;i++) rank[order[i]]=i;
    for (int key=0;key<256;key++) {
        if (atom_cell[key]<0) return false;
        int x=0,y=0;
        for (int shift=6;shift>=0;shift-=2) {
            int q=(key>>shift)&3; x=(x<<1)|(q>>1); y=(y<<1)|(q&1);
        }
        processed[x][y]=rank[atom_cell[key]]<cut;
    }
    int h[16];
    for (int x=0;x<16;x++) {
        int height=0; while (height<16 && processed[x][height]) height++;
        for (int y=0;y<16;y++) if (processed[x][y]!=(y<height)) return false;
        h[x]=height;
        if (x && h[x-1]<h[x]) return false;
    }
    *path_count=0;
    if (!append_point(path,path_count,(Point){0,256})) return false;
    for (int y=15;y>=h[0];y--) if (!append_point(path,path_count,(Point){0,y*16})) return false;
    for (int x=0;x<16;x++) {
        if (!append_point(path,path_count,(Point){(x+1)*16,h[x]*16})) return false;
        int next=(x<15)?h[x+1]:0;
        for (int y=h[x]-1;y>=next;y--)
            if (!append_point(path,path_count,(Point){(x+1)*16,y*16})) return false;
    }
    if (path[0].x!=0 || path[0].y!=256 || path[*path_count-1].x!=256 || path[*path_count-1].y!=0)
        return false;
    int32_t x0,y0,x1,y1; sweep_box(&cells[order[cut]],alternate,&x0,&y0,&x1,&y1);
    for (int i=0;i<*path_count;i++) if (path[i].x==x0 && path[i].y==y0) { *corner_index=i; return true; }
    return false;
}

static int frontier_segment(Point a,Point b,const Point *path,int count) {
    int found=-1;
    for (int i=0;i<count-1;i++) if (segments_intersect(a,b,path[i],path[i+1])) {
        if (found>=0) return -2;
        found=i;
    }
    return found;
}

static bool exit_for_cell(Point a,Point b,int32_t x0,int32_t y0,int32_t x1,int32_t y1,Exit *out,int edge_id) {
    int64_t dx=b.x-a.x,dy=b.y-a.y; int found=0;
    if (dy>0) {
        int64_t num=(int64_t)a.x*dy+(int64_t)(y1-a.y)*dx;
        if (0<y1-a.y && y1-a.y<dy && (int64_t)x0*dy<num && num<(int64_t)x1*dy) {
            out->edge_id=edge_id;out->side=0;out->numerator=num;out->denominator=dy;found++;
        }
    }
    if (dx>0) {
        int64_t num=(int64_t)a.y*dx+(int64_t)(x1-a.x)*dy;
        if (0<x1-a.x && x1-a.x<dx && (int64_t)y0*dx<num && num<(int64_t)y1*dx) {
            out->edge_id=edge_id;out->side=1;out->numerator=num;out->denominator=dx;found++;
        }
    }
    return found==1;
}

static bool exit_less(const Exit *a,const Exit *b) {
    int64_t lhs=a->numerator*b->denominator, rhs=b->numerator*a->denominator;
    return lhs<rhs || (lhs==rhs && a->edge_id<b->edge_id);
}

static bool run_sweep(const Cell *cells,int32_t c,const Edge *edges,int32_t n,
                      const int32_t endpoint_cells[MAX_EDGES][2],bool alternate,uint64_t *masks) {
    int32_t order[46],rank[46];
    for (int i=0;i<c;i++) order[i]=i;
    if (alternate) for (int i=1;i<c;i++) {
        int32_t value=order[i],j=i;
        while (j>0 && (cells[order[j-1]].alt_lo>cells[value].alt_lo
              || (cells[order[j-1]].alt_lo==cells[value].alt_lo && order[j-1]>value))) {
            order[j]=order[j-1]; j--;
        }
        order[j]=value;
    }
    for (int i=0;i<c;i++) rank[order[i]]=i;
    Point edge_a[8],edge_b[8]; int32_t direction_ids[8],direction_keys[8],count=0;
    for (int i=0;i<n;i++) if ((edges[i].alternate!=0)==alternate) {
        sweep_edge(&edges[i],alternate,&edge_a[i],&edge_b[i]);
        int key=positive_key(edge_a[i].x,edge_a[i].y);
        int j=count++;
        while (j>0 && (direction_keys[j-1]>key || (direction_keys[j-1]==key && direction_ids[j-1]>i))) {
            direction_keys[j]=direction_keys[j-1]; direction_ids[j]=direction_ids[j-1]; j--;
        }
        direction_keys[j]=key;direction_ids[j]=i;
    }
    int32_t left_stack[8],bottom_stack[8],left_count=0,bottom_count=0;
    for (int pos=0;pos<c;pos++) {
        int cid=order[pos]; int32_t x0,y0,x1,y1;
        sweep_box(&cells[cid],alternate,&x0,&y0,&x1,&y1);
        int32_t candidates[16],candidate_count=0;
        while (left_count && segment_box(&edges[left_stack[left_count-1]],&cells[cid],alternate))
            candidates[candidate_count++]=left_stack[--left_count];
        while (bottom_count && segment_box(&edges[bottom_stack[bottom_count-1]],&cells[cid],alternate))
            candidates[candidate_count++]=bottom_stack[--bottom_count];
        for (int q=0;q<count;q++) {
            int id=direction_ids[q];
            if (endpoint_cells[id][0]==cid) candidates[candidate_count++]=id;
        }
        Exit exits[16]; int exit_count=0;
        for (int q=0;q<candidate_count;q++) {
            int id=candidates[q]; masks[cid]|=((uint64_t)1)<<id;
            if (endpoint_cells[id][1]==cid) continue;
            if (!exit_for_cell(edge_a[id],edge_b[id],x0,y0,x1,y1,&exits[exit_count],id)) return false;
            exit_count++;
        }
        for (int i=1;i<exit_count;i++) {
            Exit value=exits[i]; int j=i;
            while (j>0 && (exits[j-1].side>value.side
                  || (exits[j-1].side==value.side && exit_less(&value,&exits[j-1])))) {
                exits[j]=exits[j-1];j--;
            }
            exits[j]=value;
        }
        for (int i=0;i<exit_count;i++) {
            if (exits[i].side==0) { if (left_count>=8) return false; left_stack[left_count++]=exits[i].edge_id; }
            else { if (bottom_count>=8) return false; bottom_stack[bottom_count++]=exits[i].edge_id; }
        }
        if (pos+1==c) continue;
        Point path[33]; int path_count=0,corner_index=0;
        if (!build_frontier(cells,c,order,pos+1,alternate,path,&path_count,&corner_index)) return false;
        int32_t nx0,ny0,nx1,ny1; sweep_box(&cells[order[pos+1]],alternate,&nx0,&ny0,&nx1,&ny1);
        if (ny0>y0) {
            while (left_count) {
                int id=left_stack[left_count-1];
                int crossing=frontier_segment(edge_a[id],edge_b[id],path,path_count);
                if (crossing<0) return false;
                if (crossing<corner_index) break;
                if (bottom_count>=8) return false;
                bottom_stack[bottom_count++]=left_stack[--left_count];
            }
        } else {
            while (bottom_count) {
                int id=bottom_stack[bottom_count-1];
                int crossing=frontier_segment(edge_a[id],edge_b[id],path,path_count);
                if (crossing<0) return false;
                if (crossing>=corner_index) break;
                if (left_count>=8) return false;
                left_stack[left_count++]=bottom_stack[--bottom_count];
            }
        }
    }
    return left_count==0 && bottom_count==0;
}

static bool parse_and_run(const int64_t *input,size_t length,uint64_t *masks,int32_t *cell_count) {
    if (!input || length<2 || length>MAX_WORDS) return false;
    int64_t nv=input[0],cv=input[1];
    if (nv<0 || nv>MAX_EDGES || cv<1 || cv>MAX_CELLS) return false;
    int32_t n=(int32_t)nv,c=(int32_t)cv;
    if (length!=(size_t)(2+2*c+4*n)) return false;
    Cell cells[46]={0}; Edge edges[8]={0}; int32_t endpoint_cells[8][2]={{0}};
    size_t cursor=2;
    for (int i=0;i<c;i++) {
        int64_t d=input[cursor++],p=input[cursor++];
        if (d<0 || d>MAX_DEPTH || p<0 || p >= (INT64_C(1)<<(2*d))) return false;
        cells[i].depth=(int32_t)d; cells[i].prefix=(int32_t)p;
    }
    if (!validate_partition(cells,c,n)) return false;
    for (int i=0;i<c;i++) cells[i].alt_lo=alternate_prefix(cells[i].depth,cells[i].prefix)
                                         << (2*(MAX_DEPTH-cells[i].depth));
    if (!validate_edges(input,cursor,n,edges,cells,c,endpoint_cells)) return false;
    for (int i=0;i<n;i++) for (int direction=0;direction<2;direction++) {
        if ((edges[i].alternate!=0)!=(direction!=0)) continue;
        int32_t order[46]; for (int j=0;j<c;j++) order[j]=j;
        if (direction) for (int j=1;j<c;j++) {
            int32_t value=order[j],k=j;
            while (k>0 && cells[order[k-1]].alt_lo>cells[value].alt_lo) { order[k]=order[k-1];k--; }
            order[k]=value;
        }
        int32_t start=endpoint_cells[i][0],end=endpoint_cells[i][1];
        int32_t rs=0,re=0;
        for (int k=0;k<c;k++) { if (order[k]==start) rs=k; if (order[k]==end) re=k; }
        if (rs>re) return false;
    }
    for (int i=0;i<c;i++) masks[i]=0;
    if (!run_sweep(cells,c,edges,n,endpoint_cells,false,masks)) return false;
    if (!run_sweep(cells,c,edges,n,endpoint_cells,true,masks)) return false;
    *cell_count=c; return true;
}

static void write_i64_le(uint8_t *out,size_t offset,int64_t value) {
    uint64_t word=(uint64_t)value;
    for (int i=0;i<8;i++) out[offset+i]=(uint8_t)(word>>(8*i));
}

int64_t k_quadtree_edge_distribution(const int64_t *input,size_t length,
                                     uint8_t *output,size_t capacity) {
    uint64_t masks[46]={0}; int32_t c=0;
    if (!parse_and_run(input,length,masks,&c)) return INVALID_INPUT;
    size_t bytes=8u*(size_t)(1+c);
    if (!output || capacity<bytes) return OUTPUT_ERROR;
    write_i64_le(output,0,c);
    for (int i=0;i<c;i++) write_i64_le(output,8u*(size_t)(i+1),(int64_t)masks[i]);
    return (int64_t)bytes;
}
