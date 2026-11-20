#include <cstddef>
#include <cstdint>

namespace {
constexpr int min_n=3, max_n=6, max_len=14, max_tri=4, max_all=14, max_diag=9, max_triples=20;
struct Point { std::int64_t x,y; };
struct Triangle { int a,b,c; };
struct Triangulation { Triangle triangles[max_tri]; int count; std::uint64_t edges; };
struct Fraction { std::int64_t num,den; };
struct Metrics { Fraction maximum; std::uint64_t worst; };
std::int64_t orient(Point a,Point b,Point c) { return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x); }
std::int64_t abs64(std::int64_t x) { return x<0?-x:x; }
std::int64_t gcd64(std::int64_t a,std::int64_t b) { while(b){auto r=a%b;a=b;b=r;} return a; }
Fraction fraction(std::int64_t n,std::int64_t d) { auto g=gcd64(n,d); return {n/g,d/g}; }
int cmp(Fraction a,Fraction b) { auto x=a.num*b.den,y=b.num*a.den; return x<y?-1:x>y?1:0; }
std::uint64_t edge_bit(int a,int b) { int lo=a<b?a:b,hi=a<b?b:a; return UINT64_C(1)<<(lo*max_n+hi); }
int proper_cross(const Point p[max_n],int a,int b,int c,int d) {
    return orient(p[a],p[b],p[c])*orient(p[a],p[b],p[d])<0 && orient(p[c],p[d],p[a])*orient(p[c],p[d],p[b])<0;
}
int inside_triangle(const Point p[max_n],Triangle t,int v) {
    auto dir=orient(p[t.a],p[t.b],p[t.c]);
    return orient(p[t.a],p[t.b],p[v])*dir>0 && orient(p[t.b],p[t.c],p[v])*dir>0 && orient(p[t.c],p[t.a],p[v])*dir>0;
}
Fraction triangle_score(const Point p[max_n],Triangle t,std::int64_t sides[3]) {
    Point a=p[t.a],b=p[t.b],c=p[t.c];
    sides[0]=(b.x-c.x)*(b.x-c.x)+(b.y-c.y)*(b.y-c.y);
    sides[1]=(c.x-a.x)*(c.x-a.x)+(c.y-a.y)*(c.y-a.y);
    sides[2]=(a.x-b.x)*(a.x-b.x)+(a.y-b.y)*(a.y-b.y);
    int k=sides[1]>sides[0]?1:0; if(sides[2]>sides[k])k=2;
    auto other=sides[0]+sides[1]+sides[2]-sides[k];
    if(sides[k]<=other)return {0,1};
    auto area=abs64(orient(a,b,c)),diff=sides[k]-other;
    return fraction(sides[k]*diff*diff,16*area*area);
}
int triangle_id(int a,int b,int c,int n) {
    int id=0; for(int x=0;x<n;x++)for(int y=x+1;y<n;y++)for(int z=y+1;z<n;z++){if(x==a&&y==b&&z==c)return id;id++;} return 0;
}
Metrics evaluate(const Point p[max_n],int n,const Triangulation& t) {
    Metrics m{{0,1},0};
    for(int i=0;i<t.count;i++){std::int64_t sides[3];auto s=triangle_score(p,t.triangles[i],sides);int c=cmp(s,m.maximum);
        auto bit=UINT64_C(1)<<triangle_id(t.triangles[i].a,t.triangles[i].b,t.triangles[i].c,n);
        if(c>0){m.maximum=s;m.worst=bit;}else if(c==0)m.worst|=bit;}
    return m;
}
int improves(Metrics a,Metrics b){int c=cmp(a.maximum,b.maximum);return c<0||(c==0&&a.worst!=b.worst&&(a.worst&b.worst)==a.worst);}
int popcount64(std::uint64_t x){int n=0;while(x){x&=x-1;n++;}return n;}
int preferable(Metrics a,Metrics b){int c=cmp(a.maximum,b.maximum);if(c)return c<0;int x=popcount64(a.worst),y=popcount64(b.worst);return x!=y?x<y:a.worst<b.worst;}
int enumerate(const Point p[max_n],int n,Triangulation out[max_all]) {
    int da[max_diag],db[max_diag],m=0;
    for(int a=0;a<n;a++)for(int b=a+2;b<n;b++){if(a==0&&b==n-1)continue;da[m]=a;db[m++]=b;}
    std::uint64_t boundary=0;for(int a=0;a<n;a++)boundary|=edge_bit(a,(a+1)%n);
    int total=0;
    for(int mask=0;mask<(1<<m);mask++){
        int count=0;for(int i=0;i<m;i++)if((mask>>i)&1)count++;if(count!=n-3)continue;
        bool crossing=false;for(int i=0;i<m&&!crossing;i++)if((mask>>i)&1)for(int j=i+1;j<m;j++)if((mask>>j)&1&&proper_cross(p,da[i],db[i],da[j],db[j])){crossing=true;break;}
        if(crossing)continue;
        auto edges=boundary;for(int i=0;i<m;i++)if((mask>>i)&1)edges|=edge_bit(da[i],db[i]);
        Triangle faces[max_tri];int nf=0;
        for(int a=0;a<n;a++)for(int b=a+1;b<n;b++)for(int c=b+1;c<n;c++){
            if(!(edges&edge_bit(a,b))||!(edges&edge_bit(b,c))||!(edges&edge_bit(c,a)))continue;
            bool contains=false;for(int v=0;v<n;v++)if(v!=a&&v!=b&&v!=c&&inside_triangle(p,{a,b,c},v)){contains=true;break;}
            if(!contains&&nf<max_tri)faces[nf++]={a,b,c};
        }
        if(nf==n-2&&total<max_all){out[total].count=nf;out[total].edges=edges;for(int i=0;i<nf;i++)out[total].triangles[i]=faces[i];total++;}
    }
    return total;
}
int rank_score(const Point p[max_n],int n,Fraction target){Fraction seen[max_triples];int count=0;
    for(int a=0;a<n;a++)for(int b=a+1;b<n;b++)for(int c=b+1;c<n;c++){std::int64_t sides[3];auto s=triangle_score(p,{a,b,c},sides);if(cmp(s,target)>=0)continue;bool found=false;for(int i=0;i<count;i++)if(cmp(s,seen[i])==0){found=true;break;}if(!found)seen[count++]=s;}return count+1;}
std::int64_t solve(const Point p[max_n],int n){
    Triangulation all[max_all]{};int total=enumerate(p,n,all);Triangulation fan{};
    for(int k=1;k<n-1;k++)fan.triangles[fan.count++]={0,k,k+1};
    for(int a=0;a<n;a++)fan.edges|=edge_bit(a,(a+1)%n);for(int k=2;k<n-1;k++)fan.edges|=edge_bit(0,k);
    int current_index=-1;for(int i=0;i<total;i++)if(all[i].edges==fan.edges){current_index=i;break;}if(current_index<0)return -1;
    Triangulation current=all[current_index];Metrics cm=evaluate(p,n,current);
    for(int step=0;step<max_all;step++){bool changed=false;
        for(int ti=0;ti<current.count&&!changed;ti++){Triangle t=current.triangles[ti];std::int64_t sides[3];auto score=triangle_score(p,t,sides);if(cmp(score,cm.maximum)!=0||score.num==0)continue;
            int largest=0;if(sides[1]>sides[largest])largest=1;if(sides[2]>sides[largest])largest=2;int vtx[3]={t.a,t.b,t.c};
            for(int ap=0;ap<3&&!changed;ap++){if(sides[ap]!=sides[largest])continue;int q=vtx[ap],opp[2],used=0;for(int k=0;k<3;k++)if(k!=ap)opp[used++]=vtx[k];
                for(int s=0;s<n&&!changed;s++){auto added=edge_bit(q,s);if(s==q||(current.edges&added)||!proper_cross(p,q,s,opp[0],opp[1]))continue;auto retained=current.edges;
                    for(int u=0;u<n;u++)for(int v=u+1;v<n;v++){auto bit=edge_bit(u,v);if((retained&bit)&&proper_cross(p,q,s,u,v))retained&=~bit;}
                    int selected=-1;Metrics sm{{0,1},0};for(int ci=0;ci<total;ci++){if(!(all[ci].edges&added)||(all[ci].edges&retained)!=retained)continue;auto cand=evaluate(p,n,all[ci]);if(!improves(cand,cm))continue;if(selected<0||preferable(cand,sm)){selected=ci;sm=cand;}}
                    if(selected>=0){current=all[selected];cm=sm;changed=true;}
                }
            }
        }
        if(!changed)break;
    }
    return rank_score(p,n,cm.maximum);
}
}

extern "C" std::int64_t convex_polygon_minimax_eccentricity_edge_insertion(const std::int64_t* input,std::size_t length){
    if(input==nullptr||length<1||length>max_len||input[0]<min_n||input[0]>max_n)return -1;int n=static_cast<int>(input[0]);if(length!=static_cast<std::size_t>(1+2*n))return -1;
    Point p[max_n]{};for(int i=0;i<n;i++){p[i]={input[1+2*i],input[2+2*i]};if(p[i].x < -4||p[i].x>4||p[i].y < -4||p[i].y>4)return -1;for(int j=0;j<i;j++)if(p[i].x==p[j].x&&p[i].y==p[j].y)return -1;}
    std::int64_t area2=0;for(int i=0;i<n;i++){int j=(i+1)%n;area2+=p[i].x*p[j].y-p[i].y*p[j].x;}if(area2==0)return -1;int direction=area2>0?1:-1;
    for(int a=0;a<n;a++)for(int b=a+1;b<n;b++)for(int c=b+1;c<n;c++)if(orient(p[a],p[b],p[c])==0)return -1;
    for(int e=0;e<n;e++){int j=(e+1)%n;for(int v=0;v<n;v++)if(v!=e&&v!=j&&direction*orient(p[e],p[j],p[v])<=0)return -1;}
    return solve(p,n);
}
