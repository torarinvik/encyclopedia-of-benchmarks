#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxV = 24, kMaxF = 8, kMaxD = 8, kMaxE = 32, kMaxIn = 122, kMaxOut = 386;
struct Edge { int u, v, first_face, second_face, uses; };

bool integral(double value, int low, int high, int& result) {
    if (!std::isfinite(value) || std::trunc(value) != value || value < low || value > high) return false;
    result = static_cast<int>(value);
    return true;
}
double mean(const double* values, int count) {
    double scale = 0.0;
    for (int i = 0; i < count; ++i) scale = std::max(scale, std::abs(values[i]));
    if (scale == 0.0) return 0.0;
    double sum = 0.0;
    for (int i = 0; i < count; ++i) sum += values[i] / scale;
    return (sum / count) * scale;
}
double average4(double a, double b, double c, double d) {
    const double scale = std::max({std::abs(a), std::abs(b), std::abs(c), std::abs(d)});
    return scale == 0.0 ? 0.0 : ((a/scale + b/scale + c/scale + d/scale) * 0.25) * scale;
}
}

extern "C" std::int64_t catmull_clark_subdivision(const double* input, std::size_t length,
        double* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > kMaxIn) return -1;
    for (std::size_t i=0; i<length; ++i) if (!std::isfinite(input[i])) return -1;
    int vertex_count, face_count;
    if (!integral(input[0],0,kMaxV,vertex_count) || !integral(input[1],0,kMaxF,face_count)) return -1;
    if ((vertex_count==0 || face_count==0) && !(vertex_count==0 && face_count==0 && length==2)) return -1;
    double x[kMaxV]{}, y[kMaxV]{};
    int degree[kMaxF]{}, face[kMaxF][kMaxD]{};
    std::size_t pos=2;
    if (pos + 2*static_cast<std::size_t>(vertex_count) > length) return -1;
    for (int v=0; v<vertex_count; ++v) { x[v]=input[pos++]; y[v]=input[pos++]; }
    Edge edges[kMaxE]{}; int edge_count=0;
    for (int f=0; f<face_count; ++f) {
        if (pos>=length || !integral(input[pos++],3,kMaxD,degree[f]) || pos+degree[f]>length) return -1;
        for (int i=0; i<degree[f]; ++i) {
            if (!integral(input[pos++],0,vertex_count-1,face[f][i])) return -1;
            for (int j=0;j<i;++j) if(face[f][i]==face[f][j]) return -1;
        }
        for (int i=0;i<degree[f];++i) {
            int a=face[f][i], b=face[f][(i+1)%degree[f]], u=std::min(a,b), v=std::max(a,b), found=-1;
            for(int e=0;e<edge_count;++e) if(edges[e].u==u&&edges[e].v==v){found=e;break;}
            if(found<0){if(edge_count==kMaxE)return -1; found=edge_count++; edges[found]={u,v,f,-1,1};}
            else {if(edges[found].uses!=1||edges[found].first_face==f)return -1; edges[found].uses=2;edges[found].second_face=f;}
        }
    }
    if(pos!=length)return -1;
    for(int e=0;e<edge_count;++e)if(edges[e].uses!=2)return -1;
    for(int v=0;v<vertex_count;++v){
        int la[kMaxF]{},lb[kMaxF]{},links=0,valence=0;
        for(int e=0;e<edge_count;++e)if(edges[e].u==v||edges[e].v==v)++valence;
        for(int f=0;f<face_count;++f)for(int i=0;i<degree[f];++i)if(face[f][i]==v){
            int a=face[f][(i+degree[f]-1)%degree[f]],b=face[f][(i+1)%degree[f]],lo=std::min(a,b),hi=std::max(a,b);
            for(int j=0;j<links;++j)if(std::min(la[j],lb[j])==lo&&std::max(la[j],lb[j])==hi)return -1;
            la[links]=a;lb[links++]=b;
        }
        if(valence<3||links!=valence)return -1;
        bool reached[kMaxV]{};reached[la[0]]=true;bool changed=true;
        while(changed){changed=false;for(int i=0;i<links;++i){if(reached[la[i]]&&!reached[lb[i]]){reached[lb[i]]=true;changed=true;}if(reached[lb[i]]&&!reached[la[i]]){reached[la[i]]=true;changed=true;}}}
        int nd[kMaxV]{};for(int i=0;i<links;++i){++nd[la[i]];++nd[lb[i]];}int nodes=0;
        for(int u=0;u<vertex_count;++u)if(nd[u]){++nodes;if(nd[u]!=2||!reached[u])return -1;}if(nodes<3)return -1;
    }
    std::sort(edges,edges+edge_count,[](const Edge&a,const Edge&b){return a.u<b.u||(a.u==b.u&&a.v<b.v);});
    double fx[kMaxF]{},fy[kMaxF]{};
    for(int f=0;f<face_count;++f){double vx[kMaxD],vy[kMaxD];for(int i=0;i<degree[f];++i){vx[i]=x[face[f][i]];vy[i]=y[face[f][i]];}fx[f]=mean(vx,degree[f]);fy[f]=mean(vy,degree[f]);}
    double staged[kMaxOut];std::size_t out=0;int new_v=vertex_count+edge_count+face_count,new_f=0;for(int f=0;f<face_count;++f)new_f+=degree[f];
    staged[out++]=new_v;staged[out++]=new_f;
    for(int v=0;v<vertex_count;++v){double fxs[kMaxF],fys[kMaxF],rx[kMaxF],ry[kMaxF];int nf=0,ne=0;
        for(int f=0;f<face_count;++f){for(int i=0;i<degree[f];++i)if(face[f][i]==v){fxs[nf]=fx[f];fys[nf++]=fy[f];break;}}
        for(int e=0;e<edge_count;++e)if(edges[e].u==v||edges[e].v==v){double a[2]={x[edges[e].u],x[edges[e].v]},b[2]={y[edges[e].u],y[edges[e].v]};rx[ne]=mean(a,2);ry[ne]=mean(b,2);++ne;}
        double fxa=mean(fxs,nf),fya=mean(fys,nf),rxa=mean(rx,ne),rya=mean(ry,ne),sx=std::max({std::abs(x[v]),std::abs(fxa),std::abs(rxa)}),sy=std::max({std::abs(y[v]),std::abs(fya),std::abs(rya)});
        staged[out++]=sx==0?0:((fxa/sx+2*rxa/sx+(ne-3)*(x[v]/sx))/ne)*sx;
        staged[out++]=sy==0?0:((fya/sy+2*rya/sy+(ne-3)*(y[v]/sy))/ne)*sy;
    }
    for(int e=0;e<edge_count;++e){auto z=edges[e];staged[out++]=average4(x[z.u],x[z.v],fx[z.first_face],fx[z.second_face]);staged[out++]=average4(y[z.u],y[z.v],fy[z.first_face],fy[z.second_face]);}
    for(int f=0;f<face_count;++f){staged[out++]=fx[f];staged[out++]=fy[f];}
    for(int f=0;f<face_count;++f)for(int i=0;i<degree[f];++i){int v=face[f][i],n=face[f][(i+1)%degree[f]],p=face[f][(i+degree[f]-1)%degree[f]],en=-1,ep=-1;
        int u1=std::min(v,n),v1=std::max(v,n),u2=std::min(p,v),v2=std::max(p,v);
        for(int e=0;e<edge_count;++e){if(edges[e].u==u1&&edges[e].v==v1)en=e;if(edges[e].u==u2&&edges[e].v==v2)ep=e;}
        staged[out++]=v;staged[out++]=vertex_count+en;staged[out++]=vertex_count+edge_count+f;staged[out++]=vertex_count+ep;
    }
    if(out>kMaxOut)return -1;if(output==nullptr||capacity<out)return -2;std::copy_n(staged,out,output);return static_cast<std::int64_t>(out);
}
