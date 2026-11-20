#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <numeric>
#include <vector>

namespace {
using I = std::int64_t;
struct Rat { I n, d; };
struct IPoint { I x, y; };
struct Point { Rat x, y; };
struct Event { Rat t; int id; };
struct Crossing { Point p; Rat ta, tb; bool ae, ax, be, bx; };
struct Node { Point p; int crossing; };
using Poly = std::vector<IPoint>;
using Ring = std::vector<Point>;

Rat make_rat(I n, I d) {
    if (d < 0) { n = -n; d = -d; }
    I g = std::gcd(n < 0 ? -n : n, d);
    if (g == 0) g = 1;
    return {n / g, d / g};
}
bool less_rat(Rat a, Rat b) { return a.n * b.d < b.n * a.d; }
bool equal_rat(Rat a, Rat b) { return a.n == b.n && a.d == b.d; }
bool less_point(Point a, Point b) {
    if (!equal_rat(a.x, b.x)) return less_rat(a.x, b.x);
    return less_rat(a.y, b.y);
}
bool equal_point(Point a, Point b) { return equal_rat(a.x, b.x) && equal_rat(a.y, b.y); }
I orient(IPoint a, IPoint b, IPoint c) {
    return (b.x-a.x)*(c.y-a.y) - (b.y-a.y)*(c.x-a.x);
}
bool on_segment(IPoint a, IPoint b, IPoint p) {
    return orient(a,b,p)==0 && std::min(a.x,b.x)<=p.x && p.x<=std::max(a.x,b.x)
        && std::min(a.y,b.y)<=p.y && p.y<=std::max(a.y,b.y);
}
int relation(IPoint a, IPoint b, IPoint c, IPoint d) {
    I o1=orient(a,b,c), o2=orient(a,b,d), o3=orient(c,d,a), o4=orient(c,d,b);
    if (((o1>0&&o2<0)||(o1<0&&o2>0)) && ((o3>0&&o4<0)||(o3<0&&o4>0))) return 1;
    if ((o1==0&&on_segment(a,b,c)) || (o2==0&&on_segment(a,b,d))
        || (o3==0&&on_segment(c,d,a)) || (o4==0&&on_segment(c,d,b))) return 2;
    return 0;
}
bool valid_poly(const Poly& p) {
    const int n=static_cast<int>(p.size()); I area=0;
    for (int i=0;i<n;++i) {
        const auto prev=p[(i+n-1)%n], here=p[i], next=p[(i+1)%n];
        area += here.x*next.y-here.y*next.x;
        if (orient(prev,here,next)==0) return false;
        for (int j=0;j<i;++j) if (p[i].x==p[j].x&&p[i].y==p[j].y) return false;
    }
    if (area<=0) return false;
    for (int i=0;i<n;++i) for (int j=i+1;j<n;++j) {
        if (j==i+1 || (i==0&&j==n-1)) continue;
        if (relation(p[i],p[(i+1)%n],p[j],p[(j+1)%n])!=0) return false;
    }
    return true;
}
bool inside(IPoint p, const Poly& poly) {
    int winding=0;
    for (int i=0;i<static_cast<int>(poly.size());++i) {
        IPoint a=poly[i], b=poly[(i+1)%poly.size()]; I side=orient(a,b,p);
        if (a.y<=p.y&&p.y<b.y&&side>0) ++winding;
        else if (b.y<=p.y&&p.y<a.y&&side<0) --winding;
    }
    return winding!=0;
}
Point crossing_point(IPoint a, IPoint b, IPoint c, IPoint d, Rat& ta, Rat& tb) {
    I rx=b.x-a.x, ry=b.y-a.y, sx=d.x-c.x, sy=d.y-c.y;
    I den=rx*sy-ry*sx, tn=(c.x-a.x)*sy-(c.y-a.y)*sx;
    I un=(c.x-a.x)*ry-(c.y-a.y)*rx;
    if (den<0) { den=-den; tn=-tn; un=-un; }
    ta=make_rat(tn,den); tb=make_rat(un,den);
    return {make_rat(a.x*den+rx*tn,den), make_rat(a.y*den+ry*tn,den)};
}
Point integer_point(IPoint p) { return {{p.x,1},{p.y,1}}; }

std::vector<Node> make_nodes(const Poly& poly, const std::vector<Crossing>& crossings,
                             const std::vector<std::vector<Event>>& events,
                             bool from_a, std::vector<int>& positions) {
    std::vector<Node> nodes;
    for (int edge=0;edge<static_cast<int>(poly.size());++edge) {
        nodes.push_back({integer_point(poly[edge]),-1});
        auto ordered=events[edge];
        std::sort(ordered.begin(),ordered.end(),[](Event x,Event y){
            return less_rat(x.t,y.t) || (equal_rat(x.t,y.t)&&x.id<y.id);
        });
        for (const auto e: ordered) {
            positions[e.id]=static_cast<int>(nodes.size());
            nodes.push_back({crossings[e.id].p,e.id});
        }
    }
    (void)from_a;
    return nodes;
}

void canonicalize(std::vector<Ring>& rings) {
    for (auto& ring:rings) {
        auto pivot=std::min_element(ring.begin(),ring.end(),less_point);
        std::rotate(ring.begin(),pivot,ring.end());
    }
    std::sort(rings.begin(),rings.end(),[](const Ring& a,const Ring& b){
        return std::lexicographical_compare(a.begin(),a.end(),b.begin(),b.end(),less_point);
    });
}
void put_i64(std::uint8_t* out,std::size_t offset,I value) {
    const auto bits=static_cast<std::uint64_t>(value);
    for (std::size_t i=0;i<8;++i) out[offset+i]=static_cast<std::uint8_t>(bits>>(8*i));
}
} // namespace

extern "C" std::int64_t weiler_atherton_polygon_intersection(
    const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t capacity) {
    if (!input||length<2||length>27) return -1;
    const I na=input[0], nb=input[1];
    if (na<3||na>6||nb<3||nb>6||length!=static_cast<std::size_t>(2+2*na+2*nb)) return -1;
    Poly a,b; std::size_t cursor=2;
    for (I i=0;i<na;++i) { I x=input[cursor++],y=input[cursor++]; if(x < -16||x>16||y < -16||y>16)return -1; a.push_back({x,y}); }
    for (I i=0;i<nb;++i) { I x=input[cursor++],y=input[cursor++]; if(x < -16||x>16||y < -16||y>16)return -1; b.push_back({x,y}); }
    if(!valid_poly(a)||!valid_poly(b)) return -1;

    std::vector<Crossing> crossings;
    std::vector<std::vector<Event>> ea(na),eb(nb);
    for(int i=0;i<na;++i) for(int j=0;j<nb;++j) {
        IPoint a0=a[i],a1=a[(i+1)%na],b0=b[j],b1=b[(j+1)%nb];
        int rel=relation(a0,a1,b0,b1); if(rel==2)return -1;
        if(rel==1) {
            Rat ta{},tb{}; Point p=crossing_point(a0,a1,b0,b1,ta,tb);
            I ab=orient(b0,b1,a0), aa=orient(b0,b1,a1), bb=orient(a0,a1,b0), ba=orient(a0,a1,b1);
            Crossing c{p,ta,tb,ab<0&&aa>0,ab>0&&aa<0,bb<0&&ba>0,bb>0&&ba<0};
            if((!c.ae&&!c.ax)||(!c.be&&!c.bx)||c.ae==c.be)return -1;
            int id=static_cast<int>(crossings.size()); crossings.push_back(c);
            ea[i].push_back({ta,id}); eb[j].push_back({tb,id});
        }
    }

    std::vector<Ring> rings;
    if(crossings.empty()) {
        if(inside(a[0],b)) { Ring r; for(auto p:a)r.push_back(integer_point(p)); rings.push_back(std::move(r)); }
        else if(inside(b[0],a)) { Ring r; for(auto p:b)r.push_back(integer_point(p)); rings.push_back(std::move(r)); }
    } else {
        std::vector<int> pa(crossings.size(),-1),pb(crossings.size(),-1);
        auto na_nodes=make_nodes(a,crossings,ea,true,pa);
        auto nb_nodes=make_nodes(b,crossings,eb,false,pb);
        std::vector<bool> visited(crossings.size(),false);
        for(int start=0;start<static_cast<int>(na_nodes.size());++start) {
            int sid=na_nodes[start].crossing;
            if(sid<0||!crossings[sid].ae||visited[sid])continue;
            Ring ring{na_nodes[start].p}; visited[sid]=true;
            bool active_a=true; int index=start,guard=0;
            while(true) {
                if(++guard>2*static_cast<int>(crossings.size())+na+nb+1)return -1;
                const auto& nodes=active_a?na_nodes:nb_nodes;
                int next=(index+1)%static_cast<int>(nodes.size());
                Node node=nodes[next];
                if(node.crossing>=0) {
                    int id=node.crossing; visited[id]=true;
                    if(active_a && id==sid) break;
                    bool exits=active_a?crossings[id].ax:crossings[id].bx;
                    if(exits) {
                        if(id==sid) break;
                        active_a=!active_a;
                        index=active_a?pa[id]:pb[id];
                        continue;
                    }
                }
                if(ring.size()>=48)return -1;
                ring.push_back(node.p);
                index=next;
            }
            if(ring.size()<3||ring.size()>48)return -1;
            rings.push_back(std::move(ring));
            if(rings.size()>16)return -1;
        }
        if(std::find(visited.begin(),visited.end(),false)!=visited.end())return -1;
    }
    canonicalize(rings);
    std::vector<I> words{static_cast<I>(rings.size())};
    for(const auto& ring:rings) {
        words.push_back(static_cast<I>(ring.size()));
        for(const auto p:ring) { words.push_back(p.x.n);words.push_back(p.x.d);words.push_back(p.y.n);words.push_back(p.y.d); }
    }
    if(words.size()>210)return -1;
    const std::size_t bytes=words.size()*8;
    if(output==nullptr||capacity<bytes)return -2;
    for(std::size_t i=0;i<words.size();++i)put_i64(output,i*8,words[i]);
    return static_cast<I>(bytes);
}
