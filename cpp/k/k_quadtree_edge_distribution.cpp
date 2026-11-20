#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxEdges = 8;
constexpr int kMaxCells = 46;
constexpr int kMaxDepth = 4;
constexpr std::size_t kMaxWords = 127;
constexpr std::int64_t kInvalid = -1;
constexpr std::int64_t kOutputError = -2;

struct Cell {
    std::int32_t depth = 0, prefix = 0, lo = 0, alternate_lo = 0;
    std::int32_t x0 = 0, y0 = 0, x1 = 0, y1 = 0, endpoint_count = 0;
};
struct Edge {
    std::int32_t x0 = 0, y0 = 0, x1 = 0, y1 = 0;
    std::int32_t start_cell = -1, end_cell = -1;
    bool negative = false;
};
struct Point { std::int32_t x, y; };
struct Exit { std::int32_t edge, side; std::int64_t numerator, denominator; };

std::int64_t orient(Point a, Point b, Point c) {
    return static_cast<std::int64_t>(b.x-a.x)*(c.y-a.y)
         - static_cast<std::int64_t>(b.y-a.y)*(c.x-a.x);
}
bool onSegment(Point a, Point b, Point p) {
    return p.x >= std::min(a.x,b.x) && p.x <= std::max(a.x,b.x)
        && p.y >= std::min(a.y,b.y) && p.y <= std::max(a.y,b.y);
}
bool intersects(Point a, Point b, Point c, Point d) {
    const auto o1=orient(a,b,c), o2=orient(a,b,d), o3=orient(c,d,a), o4=orient(c,d,b);
    if (o1==0 && onSegment(a,b,c)) return true;
    if (o2==0 && onSegment(a,b,d)) return true;
    if (o3==0 && onSegment(c,d,a)) return true;
    if (o4==0 && onSegment(c,d,b)) return true;
    return o1*o2<0 && o3*o4<0;
}
std::int32_t positiveKey(std::int32_t x,std::int32_t y) {
    std::int32_t key=0;
    for (int bit=7;bit>=4;--bit) key=(key<<2)|(((x>>bit)&1)<<1)|((y>>bit)&1);
    return key;
}
std::int32_t remapDigit(std::int32_t q) {
    constexpr std::array<std::int32_t,4> map{2,0,3,1};
    return map[static_cast<std::size_t>(q)];
}
std::int32_t altPrefix(std::int32_t depth,std::int32_t prefix) {
    std::int32_t result=0;
    for (int shift=2*(depth-1);shift>=0;shift-=2)
        result=(result<<2)|remapDigit((prefix>>shift)&3);
    return result;
}
void cellBox(Cell& c) {
    std::int32_t x=0,y=0;
    for (int shift=2*(c.depth-1);shift>=0;shift-=2) {
        const auto q=(c.prefix>>shift)&3;
        x=(x<<1)|(q>>1); y=(y<<1)|(q&1);
    }
    const auto side=256>>c.depth;
    c.x0=x*side; c.y0=y*side; c.x1=c.x0+side; c.y1=c.y0+side;
}
std::int32_t findCell(const std::array<Cell,kMaxCells>& cells,int c,std::int32_t key) {
    for (int i=0;i<c;++i) {
        const auto span=1<<(2*(kMaxDepth-cells[i].depth));
        if (key>=cells[i].lo && key<cells[i].lo+span) return i;
    }
    return -1;
}
bool segmentBox(const Edge& edge,const Cell& cell,bool rotated) {
    std::int32_t x0=cell.x0,y0=cell.y0,x1=cell.x1,y1=cell.y1;
    Point a{edge.x0,edge.y0},b{edge.x1,edge.y1};
    if (rotated) {
        x0=256-cell.y1; y0=cell.x0; x1=256-cell.y0; y1=cell.x1;
        a={256-edge.y0,edge.x0}; b={256-edge.y1,edge.x1};
    }
    if (a.x>=x0 && a.x<=x1 && a.y>=y0 && a.y<=y1) return true;
    if (b.x>=x0 && b.x<=x1 && b.y>=y0 && b.y<=y1) return true;
    const std::array<Point,4> corners{{{x0,y0},{x1,y0},{x1,y1},{x0,y1}}};
    for (int i=0;i<4;++i) if (intersects(a,b,corners[i],corners[(i+1)&3])) return true;
    return false;
}
void sweepBox(const Cell& cell,bool rotated,std::int32_t& x0,std::int32_t& y0,
              std::int32_t& x1,std::int32_t& y1) {
    if (rotated) { x0=256-cell.y1;y0=cell.x0;x1=256-cell.y0;y1=cell.x1; }
    else { x0=cell.x0;y0=cell.y0;x1=cell.x1;y1=cell.y1; }
}
void sweepEdge(const Edge& edge,bool rotated,Point& a,Point& b) {
    if (rotated) { a={256-edge.y0,edge.x0};b={256-edge.y1,edge.x1}; }
    else { a={edge.x0,edge.y0};b={edge.x1,edge.y1}; }
}
bool appendPoint(std::array<Point,33>& path,int& size,Point p) {
    if (size && path[static_cast<std::size_t>(size-1)].x==p.x
             && path[static_cast<std::size_t>(size-1)].y==p.y) return true;
    if (size>=33) return false;
    path[static_cast<std::size_t>(size++)]=p; return true;
}
bool frontier(const std::array<Cell,kMaxCells>& cells,int c,const std::array<int,kMaxCells>& order,
              int cut,bool rotated,std::array<Point,33>& path,int& pathSize,int& corner) {
    std::array<int,kMaxCells> rank{};
    for (int i=0;i<c;++i) rank[static_cast<std::size_t>(order[i])]=i;
    std::array<int,256> atomCell; atomCell.fill(-1);
    for (int p=0;p<c;++p) {
        const int id=order[static_cast<std::size_t>(p)]; const auto& cell=cells[static_cast<std::size_t>(id)];
        const int start=rotated?cell.alternate_lo:cell.lo;
        const int span=1<<(2*(kMaxDepth-cell.depth));
        for (int k=start;k<start+span;++k) atomCell[static_cast<std::size_t>(k)]=id;
    }
    std::array<std::array<bool,16>,16> processed{};
    for (int key=0;key<256;++key) {
        const int id=atomCell[static_cast<std::size_t>(key)]; if (id<0) return false;
        int x=0,y=0;
        for (int shift=6;shift>=0;shift-=2) {
            const int q=(key>>shift)&3; x=(x<<1)|(q>>1); y=(y<<1)|(q&1);
        }
        processed[static_cast<std::size_t>(x)][static_cast<std::size_t>(y)]
            =rank[static_cast<std::size_t>(id)]<cut;
    }
    std::array<int,16> heights{};
    for (int x=0;x<16;++x) {
        int h=0;
        while (h<16 && processed[static_cast<std::size_t>(x)][static_cast<std::size_t>(h)]) ++h;
        for (int y=0;y<16;++y)
            if (processed[static_cast<std::size_t>(x)][static_cast<std::size_t>(y)]!=(y<h)) return false;
        heights[static_cast<std::size_t>(x)]=h;
        if (x && heights[static_cast<std::size_t>(x-1)]<h) return false;
    }
    pathSize=0;
    if (!appendPoint(path,pathSize,{0,256})) return false;
    for (int y=15;y>=heights[0];--y) if (!appendPoint(path,pathSize,{0,y*16})) return false;
    for (int x=0;x<16;++x) {
        const int h=heights[static_cast<std::size_t>(x)];
        if (!appendPoint(path,pathSize,{(x+1)*16,h*16})) return false;
        const int next=x<15?heights[static_cast<std::size_t>(x+1)]:0;
        for (int y=h-1;y>=next;--y) if (!appendPoint(path,pathSize,{(x+1)*16,y*16})) return false;
    }
    if (path[0].x!=0 || path[0].y!=256 || path[static_cast<std::size_t>(pathSize-1)].x!=256
        || path[static_cast<std::size_t>(pathSize-1)].y!=0) return false;
    std::int32_t x0,y0,x1,y1; sweepBox(cells[static_cast<std::size_t>(order[cut])],rotated,x0,y0,x1,y1);
    for (int i=0;i<pathSize;++i) if (path[static_cast<std::size_t>(i)].x==x0
        && path[static_cast<std::size_t>(i)].y==y0) { corner=i; return true; }
    return false;
}
int frontierSegment(Point a,Point b,const std::array<Point,33>& path,int size) {
    int found=-1;
    for (int i=0;i<size-1;++i) if (intersects(a,b,path[static_cast<std::size_t>(i)],path[static_cast<std::size_t>(i+1)])) {
        if (found>=0) return -2;
        found=i;
    }
    return found;
}
bool exitForCell(Point a,Point b,std::int32_t x0,std::int32_t y0,std::int32_t x1,std::int32_t y1,Exit& out,int id) {
    const std::int64_t dx=b.x-a.x,dy=b.y-a.y; int found=0;
    if (dy>0) {
        const auto num=static_cast<std::int64_t>(a.x)*dy+static_cast<std::int64_t>(y1-a.y)*dx;
        if (0<y1-a.y && y1-a.y<dy && static_cast<std::int64_t>(x0)*dy<num
            && num<static_cast<std::int64_t>(x1)*dy) { out={id,0,num,dy};++found; }
    }
    if (dx>0) {
        const auto num=static_cast<std::int64_t>(a.y)*dx+static_cast<std::int64_t>(x1-a.x)*dy;
        if (0<x1-a.x && x1-a.x<dx && static_cast<std::int64_t>(y0)*dx<num
            && num<static_cast<std::int64_t>(y1)*dx) { out={id,1,num,dx};++found; }
    }
    return found==1;
}
bool exitLess(const Exit& a,const Exit& b) {
    const auto lhs=a.numerator*b.denominator,rhs=b.numerator*a.denominator;
    return lhs<rhs || (lhs==rhs && a.edge<b.edge);
}
bool runSweep(const std::array<Cell,kMaxCells>& cells,int c,const std::array<Edge,kMaxEdges>& edges,int n,
              const std::array<std::array<int,2>,kMaxEdges>& endpoints,bool rotated,
              std::array<std::uint64_t,kMaxCells>& masks) {
    std::array<int,kMaxCells> order{},rank{};
    for (int i=0;i<c;++i) order[static_cast<std::size_t>(i)]=i;
    if (rotated) std::sort(order.begin(),order.begin()+c,[&](int a,int b){
        return cells[static_cast<std::size_t>(a)].alternate_lo<cells[static_cast<std::size_t>(b)].alternate_lo;
    });
    for (int i=0;i<c;++i) rank[static_cast<std::size_t>(order[static_cast<std::size_t>(i)])]=i;
    std::array<Point,kMaxEdges> edgeA{},edgeB{};
    std::array<int,kMaxEdges> edgeIds{},edgeKeys{}; int edgeCount=0;
    for (int id=0;id<n;++id) if (edges[static_cast<std::size_t>(id)].negative==rotated) {
        sweepEdge(edges[static_cast<std::size_t>(id)],rotated,edgeA[static_cast<std::size_t>(id)],edgeB[static_cast<std::size_t>(id)]);
        const int key=positiveKey(edgeA[static_cast<std::size_t>(id)].x,edgeA[static_cast<std::size_t>(id)].y);
        int at=edgeCount++;
        while (at>0 && (edgeKeys[static_cast<std::size_t>(at-1)]>key
            || (edgeKeys[static_cast<std::size_t>(at-1)]==key && edgeIds[static_cast<std::size_t>(at-1)]>id))) {
            edgeKeys[static_cast<std::size_t>(at)]=edgeKeys[static_cast<std::size_t>(at-1)];
            edgeIds[static_cast<std::size_t>(at)]=edgeIds[static_cast<std::size_t>(at-1)]; --at;
        }
        edgeKeys[static_cast<std::size_t>(at)]=key; edgeIds[static_cast<std::size_t>(at)]=id;
    }
    std::array<int,kMaxEdges> sl{},sb{}; int sln=0,sbn=0;
    for (int pos=0;pos<c;++pos) {
        const int cid=order[static_cast<std::size_t>(pos)]; std::int32_t x0,y0,x1,y1;
        sweepBox(cells[static_cast<std::size_t>(cid)],rotated,x0,y0,x1,y1);
        std::array<int,16> candidates{}; int candidateCount=0;
        while (sln && segmentBox(edges[static_cast<std::size_t>(sl[static_cast<std::size_t>(sln-1)])],cells[static_cast<std::size_t>(cid)],rotated))
            candidates[static_cast<std::size_t>(candidateCount++)]=sl[static_cast<std::size_t>(--sln)];
        while (sbn && segmentBox(edges[static_cast<std::size_t>(sb[static_cast<std::size_t>(sbn-1)])],cells[static_cast<std::size_t>(cid)],rotated))
            candidates[static_cast<std::size_t>(candidateCount++)]=sb[static_cast<std::size_t>(--sbn)];
        for (int i=0;i<edgeCount;++i) {
            const int id=edgeIds[static_cast<std::size_t>(i)];
            if (endpoints[static_cast<std::size_t>(id)][0]==cid) candidates[static_cast<std::size_t>(candidateCount++)]=id;
        }
        std::array<Exit,16> exits{}; int exitCount=0;
        for (int i=0;i<candidateCount;++i) {
            const int id=candidates[static_cast<std::size_t>(i)]; masks[static_cast<std::size_t>(cid)]|=(std::uint64_t{1}<<id);
            if (endpoints[static_cast<std::size_t>(id)][1]==cid) continue;
            if (!exitForCell(edgeA[static_cast<std::size_t>(id)],edgeB[static_cast<std::size_t>(id)],x0,y0,x1,y1,exits[static_cast<std::size_t>(exitCount)],id)) return false;
            ++exitCount;
        }
        std::sort(exits.begin(),exits.begin()+exitCount,[](const Exit& a,const Exit& b){
            return a.side<b.side || (a.side==b.side && exitLess(a,b));
        });
        for (int i=0;i<exitCount;++i) {
            const auto e=exits[static_cast<std::size_t>(i)];
            if (e.side==0) { if (sln>=kMaxEdges) return false; sl[static_cast<std::size_t>(sln++)]=e.edge; }
            else { if (sbn>=kMaxEdges) return false; sb[static_cast<std::size_t>(sbn++)]=e.edge; }
        }
        if (pos+1==c) continue;
        std::array<Point,33> path{}; int pathSize=0,corner=0;
        if (!frontier(cells,c,order,pos+1,rotated,path,pathSize,corner)) return false;
        std::int32_t nx0,ny0,nx1,ny1; sweepBox(cells[static_cast<std::size_t>(order[static_cast<std::size_t>(pos+1)])],rotated,nx0,ny0,nx1,ny1);
        if (ny0>y0) {
            while (sln) {
                const int id=sl[static_cast<std::size_t>(sln-1)];
                const int where=frontierSegment(edgeA[static_cast<std::size_t>(id)],edgeB[static_cast<std::size_t>(id)],path,pathSize);
                if (where<0) return false;
                if (where<corner) break;
                if (sbn>=kMaxEdges) return false;
                sb[static_cast<std::size_t>(sbn++)]=sl[static_cast<std::size_t>(--sln)];
            }
        } else {
            while (sbn) {
                const int id=sb[static_cast<std::size_t>(sbn-1)];
                const int where=frontierSegment(edgeA[static_cast<std::size_t>(id)],edgeB[static_cast<std::size_t>(id)],path,pathSize);
                if (where<0) return false;
                if (where>=corner) break;
                if (sln>=kMaxEdges) return false;
                sl[static_cast<std::size_t>(sln++)]=sb[static_cast<std::size_t>(--sbn)];
            }
        }
    }
    return sln==0 && sbn==0;
}

bool parseAndRun(const std::int64_t* input,std::size_t length,
                 std::array<std::uint64_t,kMaxCells>& masks,int& cellCount) {
    if (!input || length<2 || length>kMaxWords) return false;
    const auto nv=input[0],cv=input[1];
    if (nv<0 || nv>kMaxEdges || cv<1 || cv>kMaxCells) return false;
    const int n=static_cast<int>(nv),c=static_cast<int>(cv);
    if (length!=static_cast<std::size_t>(2+2*c+4*n)) return false;
    std::array<Cell,kMaxCells> cells{}; std::array<Edge,kMaxEdges> edges{};
    std::array<std::array<int,2>,kMaxEdges> endpoints{};
    std::size_t pos=2; int previous=0;
    for (int i=0;i<c;++i) {
        const auto d=input[pos++],p=input[pos++];
        if (d<0 || d>kMaxDepth || p<0 || p>=(std::int64_t{1}<<(2*d))) return false;
        auto& cell=cells[static_cast<std::size_t>(i)]; cell.depth=static_cast<int>(d);cell.prefix=static_cast<int>(p);
        const int span=1<<(2*(kMaxDepth-cell.depth)); cell.lo=cell.prefix*span;
        if (cell.lo!=previous) return false; previous=cell.lo+span; cellBox(cell);
    }
    if (previous!=256 || (n==0 && (c!=1 || cells[0].depth!=0 || cells[0].prefix!=0))) return false;
    for (int i=0;i<c;++i) {
        auto& cell=cells[static_cast<std::size_t>(i)];
        cell.alternate_lo=altPrefix(cell.depth,cell.prefix)<<(2*(kMaxDepth-cell.depth));
    }
    std::array<Point,2*kMaxEdges> points{};
    for (int i=0;i<n;++i) {
        std::array<std::int64_t,4> v{{input[pos],input[pos+1],input[pos+2],input[pos+3]}};pos+=4;
        for (auto x:v) if (x<0 || x>255 || x%16==0) return false;
        auto x0=static_cast<int>(v[0]),y0=static_cast<int>(v[1]),x1=static_cast<int>(v[2]),y1=static_cast<int>(v[3]);
        if ((x0==x1 && y0==y1) || y0==y1) return false;
        if (x0>x1 || (x0==x1 && y0>y1)) { std::swap(x0,x1);std::swap(y0,y1); }
        if (x0==x1 && y1<=y0) return false;
        edges[static_cast<std::size_t>(i)]={x0,y0,x1,y1,-1,-1,y1<y0};
        points[static_cast<std::size_t>(2*i)]={x0,y0};points[static_cast<std::size_t>(2*i+1)]={x1,y1};
        for (int x=0;x<=256;x+=16) for (int y=0;y<=256;y+=16)
            if (orient(points[static_cast<std::size_t>(2*i)],points[static_cast<std::size_t>(2*i+1)],{x,y})==0
                && onSegment(points[static_cast<std::size_t>(2*i)],points[static_cast<std::size_t>(2*i+1)],{x,y})) return false;
        for (int j=0;j<2*i;++j) if (points[static_cast<std::size_t>(j)].x==x0 && points[static_cast<std::size_t>(j)].y==y0) return false;
        for (int j=0;j<2*i+1;++j) if (points[static_cast<std::size_t>(j)].x==x1 && points[static_cast<std::size_t>(j)].y==y1) return false;
        for (int j=0;j<i;++j) if (intersects(points[static_cast<std::size_t>(2*i)],points[static_cast<std::size_t>(2*i+1)],
                                             points[static_cast<std::size_t>(2*j)],points[static_cast<std::size_t>(2*j+1)])) return false;
        const int a=findCell(cells,c,positiveKey(x0,y0)),b=findCell(cells,c,positiveKey(x1,y1));
        if (a<0 || b<0) return false;
        endpoints[static_cast<std::size_t>(i)]={a,b};
        ++cells[static_cast<std::size_t>(a)].endpoint_count;++cells[static_cast<std::size_t>(b)].endpoint_count;
    }
    for (int i=0;i<c;++i) if (cells[static_cast<std::size_t>(i)].endpoint_count>1) return false;
    std::array<int,85> pd{},pp{};int pc=0;
    for (int i=0;i<c;++i) for (int d=0;d<cells[static_cast<std::size_t>(i)].depth;++d) {
        const int p=cells[static_cast<std::size_t>(i)].prefix>>(2*(cells[static_cast<std::size_t>(i)].depth-d));bool exists=false;
        for (int q=0;q<pc;++q) if (pd[static_cast<std::size_t>(q)]==d && pp[static_cast<std::size_t>(q)]==p) exists=true;
        if (!exists) {pd[static_cast<std::size_t>(pc)]=d;pp[static_cast<std::size_t>(pc++)]=p;}
    }
    for (int q=0;q<pc;++q) {
        unsigned occupied=0; const int d=pd[static_cast<std::size_t>(q)],p=pp[static_cast<std::size_t>(q)];
        for (int i=0;i<c;++i) {
            const auto& cell=cells[static_cast<std::size_t>(i)]; if (!cell.endpoint_count || cell.depth<=d) continue;
            if ((cell.prefix>>(2*(cell.depth-d)))==p)
                occupied|=1u<<((cell.prefix>>(2*(cell.depth-d-1)))&3);
        }
        if ((occupied&(occupied-1u))==0) return false;
    }
    for (int direction=0;direction<2;++direction) {
        const bool rotated=direction!=0;
        std::array<int,kMaxCells> order{};for (int i=0;i<c;++i) order[static_cast<std::size_t>(i)]=i;
        if (rotated) std::sort(order.begin(),order.begin()+c,[&](int a,int b){return cells[a].alternate_lo<cells[b].alternate_lo;});
        std::array<int,kMaxCells> rank{};for(int i=0;i<c;++i)rank[static_cast<std::size_t>(order[static_cast<std::size_t>(i)])]=i;
        for(int i=0;i<n;++i)if((edges[static_cast<std::size_t>(i)].negative==rotated)
            && rank[static_cast<std::size_t>(endpoints[static_cast<std::size_t>(i)][0])]
                >rank[static_cast<std::size_t>(endpoints[static_cast<std::size_t>(i)][1])])return false;
    }
    masks.fill(0);
    if(!runSweep(cells,c,edges,n,endpoints,false,masks)||!runSweep(cells,c,edges,n,endpoints,true,masks))return false;
    cellCount=c;return true;
}
void writeI64(std::uint8_t* output,std::size_t offset,std::int64_t value) {
    const auto word=static_cast<std::uint64_t>(value);
    for(int i=0;i<8;++i)output[offset+static_cast<std::size_t>(i)]=static_cast<std::uint8_t>(word>>(8*i));
}
} // namespace

extern "C" std::int64_t k_quadtree_edge_distribution(const std::int64_t* input,std::size_t length,
                                                       std::uint8_t* output,std::size_t capacity) {
    std::array<std::uint64_t,kMaxCells> masks{};int cells=0;
    if(!parseAndRun(input,length,masks,cells))return kInvalid;
    const std::size_t bytes=8u*static_cast<std::size_t>(1+cells);
    if(!output||capacity<bytes)return kOutputError;
    writeI64(output,0,cells);
    for(int i=0;i<cells;++i)writeI64(output,8u*static_cast<std::size_t>(i+1),static_cast<std::int64_t>(masks[static_cast<std::size_t>(i)]));
    return static_cast<std::int64_t>(bytes);
}
