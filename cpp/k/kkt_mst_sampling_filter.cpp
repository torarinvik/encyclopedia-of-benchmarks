#include <cstddef>
#include <cstdint>

extern "C" std::int64_t kkt_mst_sampling_filter(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    constexpr std::size_t N=12, M=24, L=98;
    if (!input || length<6 || length>L) return -1;
    const auto n64=input[0], m64=input[1];
    if (n64<2 || n64>N || m64<1 || m64>M || length!=2+4*static_cast<std::size_t>(m64)) return -1;
    const auto n=static_cast<std::size_t>(n64), m=static_cast<std::size_t>(m64);
    std::int64_t u[M]{},v[M]{},w[M]{},sample[M]{};
    for (std::size_t i=0;i<m;++i) {
        u[i]=input[2+4*i]; v[i]=input[3+4*i]; w[i]=input[4+4*i]; sample[i]=input[5+4*i];
        if (u[i]<0 || u[i]>=v[i] || v[i]>=n64 || w[i]<1 || w[i]>1024 || (sample[i]!=0 && sample[i]!=1)) return -1;
        for (std::size_t j=0;j<i;++j) if ((u[i]==u[j]&&v[i]==v[j]) || w[i]==w[j]) return -1;
    }
    if (!output || capacity<m) return -2;
    std::size_t order[M]{}; for(std::size_t i=0;i<m;++i)order[i]=i;
    for(std::size_t i=0;i<m;++i){std::size_t best=i;for(std::size_t j=i+1;j<m;++j)if(w[order[j]]<w[order[best]])best=j;auto t=order[i];order[i]=order[best];order[best]=t;}
    std::size_t parent[N]{};for(std::size_t i=0;i<n;++i)parent[i]=i;
    bool in_forest[M]{};std::uint8_t staged[M]{};
    for(std::size_t p=0;p<m;++p){auto e=order[p];if(!sample[e])continue;auto a=static_cast<std::size_t>(u[e]),b=static_cast<std::size_t>(v[e]);while(parent[a]!=a)a=parent[a];while(parent[b]!=b)b=parent[b];if(a!=b){parent[b]=a;in_forest[e]=true;}}
    for(std::size_t e=0;e<m;++e){
        if(in_forest[e]){staged[e]=1;continue;}
        std::int64_t path_max[N];std::size_t queue[N]{};bool seen[N]{};for(std::size_t i=0;i<n;++i)path_max[i]=-1;
        std::size_t head=0,tail=0,start=static_cast<std::size_t>(u[e]),target=static_cast<std::size_t>(v[e]);queue[tail++]=start;seen[start]=true;path_max[start]=0;
        while(head<tail&&!seen[target]){auto cur=queue[head++];for(std::size_t k=0;k<m;++k)if(in_forest[k]){std::int64_t next=-1;if(static_cast<std::size_t>(u[k])==cur)next=v[k];else if(static_cast<std::size_t>(v[k])==cur)next=u[k];if(next>=0&&!seen[static_cast<std::size_t>(next)]){auto q=static_cast<std::size_t>(next);seen[q]=true;path_max[q]=path_max[cur]>w[k]?path_max[cur]:w[k];queue[tail++]=q;}}}
        staged[e]=static_cast<std::uint8_t>(!seen[target]||w[e]<path_max[target]);
    }
    for(std::size_t i=0;i<m;++i)output[i]=staged[i];return static_cast<std::int64_t>(m);
}
