#include <array>
#include <cstddef>
#include <cstdint>
#include <vector>

extern "C" int64_t dbscan(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 5 || length > 67) return -1;
    const int64_t n0=input[0], eps=input[1], minimum=input[2];
    if(n0<1||n0>32||eps<1||eps>2000000||minimum<1||minimum>n0||length!=3+2*static_cast<size_t>(n0))return -1;
    size_t n=static_cast<size_t>(n0); std::array<int64_t,32>x{},y{},labels{}; std::array<bool,32>expanded{};
    for(size_t i=0;i<n;i++){x[i]=input[3+2*i];y[i]=input[4+2*i];if(x[i]<-1000000||x[i]>1000000||y[i]<-1000000||y[i]>1000000)return -1;labels[i]=-1;}
    for(size_t i=0;i<n;i++)for(size_t j=0;j<i;j++)if(x[i]==x[j]&&y[i]==y[j])return -1;
    if(!output||capacity<n)return -2; const int64_t e2=eps*eps; int64_t next=0;
    auto near=[&](size_t a,size_t b){int64_t dx=x[a]-x[b],dy=y[a]-y[b];return dx*dx+dy*dy<=e2;};
    for(size_t i=0;i<n;i++){if(labels[i]>=0)continue;size_t count=0;for(size_t j=0;j<n;j++)if(near(i,j))count++;if(count<static_cast<size_t>(minimum))continue;
        int64_t cluster=next++;labels[i]=cluster;std::vector<size_t>queue;std::array<bool,32>queued{};for(size_t j=0;j<n;j++)if(near(i,j)){queue.push_back(j);queued[j]=true;}
        for(size_t head=0;head<queue.size();head++){size_t q=queue[head];if(labels[q]>=0&&labels[q]!=cluster)continue;labels[q]=cluster;if(expanded[q])continue;expanded[q]=true;size_t nc=0;for(size_t j=0;j<n;j++)if(near(q,j))nc++;if(nc>=static_cast<size_t>(minimum))for(size_t j=0;j<n;j++)if(near(q,j)&&labels[j]<0&&!queued[j]){queue.push_back(j);queued[j]=true;}}
    }
    for(size_t i=0;i<n;i++)output[i]=static_cast<uint8_t>(labels[i]<0?0:labels[i]+1);return static_cast<int64_t>(n);
}
