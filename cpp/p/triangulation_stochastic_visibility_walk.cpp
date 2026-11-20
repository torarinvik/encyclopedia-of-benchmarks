#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxV = 6, kMaxB = 6, kMaxT = 7, kMaxCap = 12, kMaxK = 12;
using I64 = std::int64_t;

I64 orient(I64 ax, I64 ay, I64 bx, I64 by, I64 cx, I64 cy) {
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
}

bool same_edge(int a, int b, int c, int d) {
    return (a == c && b == d) || (a == d && b == c);
}

bool on_segment(I64 ax, I64 ay, I64 bx, I64 by, I64 px, I64 py) {
    return orient(ax,ay,bx,by,px,py)==0 && px>=std::min(ax,bx) && px<=std::max(ax,bx) &&
           py>=std::min(ay,by) && py<=std::max(ay,by);
}

bool segments_intersect(I64 ax,I64 ay,I64 bx,I64 by,I64 cx,I64 cy,I64 dx,I64 dy) {
    const I64 o1=orient(ax,ay,bx,by,cx,cy),o2=orient(ax,ay,bx,by,dx,dy);
    const I64 o3=orient(cx,cy,dx,dy,ax,ay),o4=orient(cx,cy,dx,dy,bx,by);
    if ((o1==0&&on_segment(ax,ay,bx,by,cx,cy))||(o2==0&&on_segment(ax,ay,bx,by,dx,dy))||
        (o3==0&&on_segment(cx,cy,dx,dy,ax,ay))||(o4==0&&on_segment(cx,cy,dx,dy,bx,by))) return true;
    return ((o1<0&&o2>0)||(o1>0&&o2<0))&&((o3<0&&o4>0)||(o3>0&&o4<0));
}
}

extern "C" I64 triangulation_stochastic_visibility_walk(const I64* input, std::size_t length) noexcept {
    if (input == nullptr || length < 8 || length > 57) return -1;
    const I64 vr=input[0], br=input[1], tr=input[2], sr=input[3];
    const I64 px=input[4], py=input[5], capr=input[6], kr=input[7];
    if (vr<3 || vr>kMaxV || br<3 || br>vr || tr!=2*vr-br-2 || tr<1 || tr>kMaxT ||
        sr<0 || sr>=tr || capr<0 || capr>kMaxCap || kr<0 || kr>kMaxK ||
        px< -200 || px>200 || py< -200 || py>200) return -1;
    const int v=static_cast<int>(vr), bcount=static_cast<int>(br), tcount=static_cast<int>(tr);
    const int start=static_cast<int>(sr), cap=static_cast<int>(capr), k=static_cast<int>(kr);
    if (length != static_cast<std::size_t>(8+2*v+bcount+3*tcount+k)) return -1;

    std::array<I64,kMaxV> x{}, y{};
    std::array<int,kMaxB> boundary{};
    std::array<std::array<int,3>,kMaxT> faces{};
    std::array<std::array<int,3>,kMaxT> neighbors{};
    std::array<bool,kMaxV> used{};
    std::size_t cursor=8;
    for (int i=0;i<v;++i) {
        x[i]=input[cursor++]; y[i]=input[cursor++];
        if (x[i]<-200 || x[i]>200 || y[i]<-200 || y[i]>200) return -1;
        for (int j=0;j<i;++j) if (x[i]==x[j] && y[i]==y[j]) return -1;
    }
    for (int i=0;i<bcount;++i) {
        const I64 id=input[cursor++];
        if (id<0 || id>=v) return -1;
        boundary[i]=static_cast<int>(id);
        for (int j=0;j<i;++j) if (boundary[i]==boundary[j]) return -1;
    }
    for (int i=0;i<bcount;++i) {
        const int a=boundary[i], b=boundary[(i+1)%bcount];
        for (int j=0;j<bcount;++j) {
            const int c=boundary[j];
            if (c!=a && c!=b && orient(x[a],y[a],x[b],y[b],x[c],y[c])<=0) return -1;
        }
    }
    for (int i=0;i<v;++i) {
        bool on_boundary=false;
        for (int j=0;j<bcount;++j) on_boundary |= boundary[j]==i;
        if (!on_boundary) for (int j=0;j<bcount;++j) {
            const int a=boundary[j], b=boundary[(j+1)%bcount];
            if (orient(x[a],y[a],x[b],y[b],x[i],y[i])<=0) return -1;
        }
    }

    I64 area_sum=0;
    for (int f=0;f<tcount;++f) {
        for (int j=0;j<3;++j) {
            const I64 id=input[cursor++];
            if (id<0 || id>=v) return -1;
            faces[f][j]=static_cast<int>(id);
        }
        const auto& face=faces[f];
        if (face[0]==face[1] || face[1]==face[2] || face[2]==face[0] ||
            orient(x[face[0]],y[face[0]],x[face[1]],y[face[1]],x[face[2]],y[face[2]])<=0) return -1;
        for (int id : face) used[id]=true;
        area_sum+=orient(x[face[0]],y[face[0]],x[face[1]],y[face[1]],x[face[2]],y[face[2]]);
        for (int prior=0;prior<f;++prior) {
            std::array<int,3> lhs=face, rhs=faces[prior];
            lhs[0]=std::min({face[0],face[1],face[2]});
            lhs[2]=std::max({face[0],face[1],face[2]});
            lhs[1]=face[0]+face[1]+face[2]-lhs[0]-lhs[2];
            rhs[0]=std::min({faces[prior][0],faces[prior][1],faces[prior][2]});
            rhs[2]=std::max({faces[prior][0],faces[prior][1],faces[prior][2]});
            rhs[1]=faces[prior][0]+faces[prior][1]+faces[prior][2]-rhs[0]-rhs[2];
            if (lhs==rhs) return -1;
        }
        neighbors[f].fill(-1);
    }
    for (int i=0;i<v;++i) if (!used[i]) return -1;
    I64 polygon_area=0;
    for (int i=0;i<bcount;++i) {
        const int a=boundary[i], b=boundary[(i+1)%bcount];
        polygon_area+=x[a]*y[b]-y[a]*x[b];
    }
    if (polygon_area<=0 || polygon_area!=area_sum) return -1;
    for (int i=0;i<bcount;++i) {
        const int a=boundary[i], b=boundary[(i+1)%bcount];
        int owners=0;
        for (int f=0;f<tcount;++f) for (int e=0;e<3;++e)
            owners+=same_edge(a,b,faces[f][e],faces[f][(e+1)%3]);
        if (owners!=1) return -1;
    }
    for (int f=0;f<tcount;++f) for (int e=0;e<3;++e) {
        const int a=faces[f][e],b=faces[f][(e+1)%3];
        bool first_copy=true;
        for (int g=0;g<=f;++g) for (int ge=0;ge<3;++ge) {
            if (g==f && ge>=e) continue;
            if (same_edge(a,b,faces[g][ge],faces[g][(ge+1)%3])) first_copy=false;
        }
        if (!first_copy) continue;
        for (int p=0;p<v;++p)
            if (p!=a && p!=b && on_segment(x[a],y[a],x[b],y[b],x[p],y[p])) return -1;
        for (int g=f;g<tcount;++g) for (int ge=0;ge<3;++ge) {
            if (g==f && ge<=e) continue;
            const int c=faces[g][ge],d=faces[g][(ge+1)%3];
            if (a==c || a==d || b==c || b==d) continue;
            if (segments_intersect(x[a],y[a],x[b],y[b],x[c],y[c],x[d],y[d])) return -1;
        }
    }
    for (int f=0;f<tcount;++f) for (int e=0;e<3;++e) {
        const int a=faces[f][e], b=faces[f][(e+1)%3];
        bool boundary_edge=false;
        for (int j=0;j<bcount;++j)
            boundary_edge |= same_edge(a,b,boundary[j],boundary[(j+1)%bcount]);
        int owners=0, other=-1, first_u=-1, first_v=-1;
        for (int g=0;g<tcount;++g) for (int ge=0;ge<3;++ge)
            if (same_edge(a,b,faces[g][ge],faces[g][(ge+1)%3])) {
                if (owners==0) { first_u=faces[g][ge]; first_v=faces[g][(ge+1)%3]; }
                else if (faces[g][ge]!=first_v || faces[g][(ge+1)%3]!=first_u) return -1;
                ++owners; if (g!=f) other=g;
            }
        if (owners!=(boundary_edge?1:2)) return -1;
        if (!boundary_edge) neighbors[f][e]=other;
    }
    for (int i=0;i<k;++i) if (input[cursor+i]<0 || input[cursor+i]>1) return -1;
    for (int i=0;i<bcount;++i) {
        const int a=boundary[i], b=boundary[(i+1)%bcount];
        if (orient(x[a],y[a],x[b],y[b],px,py)<=0) return -1;
    }
    int containing=0;
    for (int f=0;f<tcount;++f) {
        const auto& z=faces[f];
        containing += orient(x[z[0]],y[z[0]],x[z[1]],y[z[1]],px,py)>0 &&
                      orient(x[z[1]],y[z[1]],x[z[2]],y[z[2]],px,py)>0 &&
                      orient(x[z[2]],y[z[2]],x[z[0]],y[z[0]],px,py)>0;
    }
    if (containing!=1) return -1;

    int face=start, steps=0, choice_index=0, status=0;
    I64 trace=face+1, predicates=0;
    for (;;) {
        const auto& z=faces[face];
        const int eu[3]={z[0],z[1],z[2]}, ev[3]={z[1],z[2],z[0]};
        int eligible[3], count=0;
        for (int e=0;e<3;++e) {
            ++predicates;
            if (orient(x[eu[e]],y[eu[e]],x[ev[e]],y[ev[e]],px,py)<0) eligible[count++]=e;
        }
        if (count==0) { status=0; break; }
        if (steps==cap) { status=2; break; }
        int selected;
        if (count==1) selected=eligible[0];
        else if (count==2) {
            if (choice_index==k) { status=1; break; }
            selected=eligible[static_cast<int>(input[cursor+choice_index++])];
        } else return -1;
        face=neighbors[face][selected];
        if (face<0) return -1;
        ++steps;
        trace=trace*9+face+1;
    }
    return (trace*40+predicates)*3+status;
}
