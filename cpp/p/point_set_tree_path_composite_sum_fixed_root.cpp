#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::size_t NMAX=16, QMAX=32, BASE=16, INPUT_MAX=5*NMAX+4*QMAX-2;
constexpr std::int64_t MOD=998244353;
using Pair=std::array<std::int64_t,2>;
Pair compose(Pair l, Pair r) { return {l[0]*r[0]%MOD,(l[0]*r[1]+l[1])%MOD}; }
std::size_t root(std::array<std::size_t,NMAX>& p,std::size_t x) {
    while(p[x]!=x){p[x]=p[p[x]];x=p[x];} return x;
}
void store(std::uint8_t* out,std::size_t at,std::int64_t x) {
    auto bits=static_cast<std::uint64_t>(x);
    for(std::size_t i=0;i<8;++i) out[at+i]=static_cast<std::uint8_t>(bits>>(8*i));
}
}

extern "C" std::int64_t point_set_tree_path_composite_sum_fixed_root(
    const std::int64_t* in,std::size_t len,std::uint8_t* out,std::size_t cap) noexcept {
    if(!in||len<2||len>INPUT_MAX) return -1;
    auto nr=in[0], qr=in[1];
    if(nr<1||nr>static_cast<std::int64_t>(NMAX)||qr<1||qr>static_cast<std::int64_t>(QMAX)) return -1;
    auto n=static_cast<std::size_t>(nr),q=static_cast<std::size_t>(qr),cur=std::size_t{2};
    std::array<std::int64_t,NMAX> val{};
    for(std::size_t u=0;u<n;++u){if(cur>=len)return -1;val[u]=in[cur++];if(val[u]<0||val[u]>=MOD)return -1;}
    std::array<std::array<int,NMAX>,NMAX> eid{}; for(auto& row:eid) row.fill(-1);
    std::array<std::size_t,NMAX-1> eu{},ev{};
    std::array<std::int64_t,NMAX-1> eb{},ec{};
    std::array<std::size_t,NMAX> dsu{},dsz{};
    for(std::size_t u=0;u<n;++u){dsu[u]=u;dsz[u]=1;}
    for(std::size_t e=0;e+1<n;++e){
        if(cur+4>len)return -1;
        auto ur=in[cur++],vr=in[cur++],b=in[cur++],c=in[cur++];
        if(ur<0||ur>=nr||vr<0||vr>=nr||ur==vr||b<1||b>=MOD||c<0||c>=MOD)return -1;
        auto u=static_cast<std::size_t>(ur),v=static_cast<std::size_t>(vr),ru=root(dsu,u),rv=root(dsu,v);
        if(ru==rv)return -1; if(dsz[ru]<dsz[rv])std::swap(ru,rv);
        dsu[rv]=ru;dsz[ru]+=dsz[rv];eu[e]=u;ev[e]=v;eb[e]=b;ec[e]=c;eid[u][v]=eid[v][u]=static_cast<int>(e);
    }
    struct Op{std::int64_t kind,x,y,z;}; std::array<Op,QMAX> ops{};
    for(std::size_t i=0;i<q;++i){
        if(cur>=len)return -1; auto kind=in[cur++];
        if(kind==0){if(cur+2>len)return -1;auto x=in[cur++],y=in[cur++];if(x<0||x>=nr||y<0||y>=MOD)return -1;ops[i]={0,x,y,0};}
        else if(kind==1){if(cur+3>len)return -1;auto x=in[cur++],y=in[cur++],z=in[cur++];if(x<0||x>=nr-1||y<1||y>=MOD||z<0||z>=MOD)return -1;ops[i]={1,x,y,z};}
        else return -1;
    }
    if(cur!=len)return -1;
    const auto bytes=8*q; if(!out||cap<bytes)return -2;

    std::array<std::int64_t,NMAX> parent{},pedge{},depth{};parent.fill(-2);pedge.fill(-1);
    std::array<std::size_t,NMAX> order{},stack{};std::size_t count=0,top=0;parent[0]=-1;stack[top++]=0;
    while(top){auto u=stack[--top];order[count++]=u;for(std::size_t v=0;v<n;++v)if(eid[u][v]>=0&&static_cast<std::int64_t>(v)!=parent[u]){parent[v]=static_cast<std::int64_t>(u);pedge[v]=eid[u][v];depth[v]=depth[u]+1;stack[top++]=v;}}
    std::array<std::size_t,NMAX> sub{};sub.fill(1);std::array<std::int64_t,NMAX> heavy{};heavy.fill(-1);
    for(std::size_t i=count;i>0;--i){auto u=order[i-1];std::size_t best=0;for(std::size_t v=0;v<n;++v)if(parent[v]==static_cast<std::int64_t>(u)){sub[u]+=sub[v];if(sub[v]>best||(sub[v]==best&&(heavy[u]<0||v<static_cast<std::size_t>(heavy[u])))){best=sub[v];heavy[u]=static_cast<std::int64_t>(v);}}}
    std::array<std::size_t,NMAX> head{},pos{},end{},chs{};std::size_t timer=0;top=0;chs[top++]=0;
    while(top){auto h=chs[--top],u=h;do{head[u]=h;pos[u]=timer++;for(std::size_t v=0;v<n;++v)if(parent[v]==static_cast<std::int64_t>(u)&&static_cast<std::int64_t>(v)!=heavy[u])chs[top++]=v;u=heavy[u]<0?n:static_cast<std::size_t>(heavy[u]);}while(u<n);end[h]=timer;}
    std::array<std::int64_t,NMAX> down{};
    for(std::size_t i=count;i>0;--i){auto u=order[i-1];auto sum=val[u];for(std::size_t v=0;v<n;++v)if(parent[v]==static_cast<std::int64_t>(u)){auto e=static_cast<std::size_t>(pedge[v]);sum+=eb[e]*down[v]+ec[e]*static_cast<std::int64_t>(sub[v]);}down[u]=sum%MOD;}
    std::array<std::int64_t,NMAX> lm{},la{};
    for(std::size_t u=0;u<n;++u){la[u]=val[u];for(std::size_t v=0;v<n;++v)if(parent[v]==static_cast<std::int64_t>(u)){auto e=static_cast<std::size_t>(pedge[v]);if(static_cast<std::int64_t>(v)==heavy[u]){lm[u]=eb[e];la[u]+=ec[e]*static_cast<std::int64_t>(sub[v]);}else la[u]+=eb[e]*down[v]+ec[e]*static_cast<std::int64_t>(sub[v]);}la[u]%=MOD;}
    std::array<Pair,2*BASE> seg{};seg.fill(Pair{1,0});for(std::size_t u=0;u<n;++u)seg[BASE+pos[u]]={lm[u],la[u]};for(std::size_t i=BASE-1;i>0;--i)seg[i]=compose(seg[2*i],seg[2*i+1]);
    auto set_leaf=[&](std::size_t u){auto k=BASE+pos[u];seg[k]={lm[u],la[u]};while((k/=2)>0)seg[k]=compose(seg[2*k],seg[2*k+1]);};
    auto chain_value=[&](std::size_t h){auto l=BASE+pos[h],r=BASE+end[h];Pair a{1,0},b{1,0};while(l<r){if(l&1)a=compose(a,seg[l++]);if(r&1)b=compose(seg[--r],b);l/=2;r/=2;}return compose(a,b)[1];};
    std::array<std::int64_t,NMAX> current{};for(std::size_t u=0;u<n;++u)if(head[u]==u)current[u]=down[u];
    auto propagate=[&](std::size_t u){while(true){auto h=head[u];auto old=current[h];current[h]=chain_value(h);if(h==0)break;auto p=static_cast<std::size_t>(parent[h]),e=static_cast<std::size_t>(pedge[h]);la[p]=(la[p]+eb[e]*(current[h]-old))%MOD;if(la[p]<0)la[p]+=MOD;set_leaf(p);u=p;}};
    for(std::size_t i=0;i<q;++i){auto op=ops[i];std::size_t start;
        if(op.kind==0){auto u=static_cast<std::size_t>(op.x);la[u]=(la[u]+op.y-val[u])%MOD;if(la[u]<0)la[u]+=MOD;val[u]=op.y;set_leaf(u);start=u;}
        else{auto e=static_cast<std::size_t>(op.x),u=eu[e],v=ev[e];auto child=parent[u]==static_cast<std::int64_t>(v)?u:v,p=static_cast<std::size_t>(parent[child]);auto ob=eb[e],oc=ec[e];if(heavy[p]==static_cast<std::int64_t>(child)){lm[p]=op.y;la[p]=(la[p]+(op.z-oc)*static_cast<std::int64_t>(sub[child]))%MOD;}else la[p]=(la[p]+(op.y-ob)*current[child]+(op.z-oc)*static_cast<std::int64_t>(sub[child]))%MOD;if(la[p]<0)la[p]+=MOD;eb[e]=op.y;ec[e]=op.z;set_leaf(p);start=p;}
        propagate(start);store(out,8*i,current[0]);
    }
    return static_cast<std::int64_t>(bytes);
}
