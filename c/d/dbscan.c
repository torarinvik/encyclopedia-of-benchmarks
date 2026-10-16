#include <stddef.h>
#include <stdint.h>

#define MAX_POINTS 32
#define MAX_INPUT_LENGTH (3 + 2 * MAX_POINTS)

int64_t dbscan(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    int64_t n64 = input[0], eps = input[1], min_pts = input[2];
    if (n64 < 1 || n64 > MAX_POINTS || eps < 1 || eps > 2000000 || min_pts < 1 || min_pts > n64 || length != 3 + 2 * (size_t)n64) return -1;
    int64_t x[MAX_POINTS], y[MAX_POINTS], labels[MAX_POINTS];
    uint8_t expanded[MAX_POINTS] = {0};
    size_t n = (size_t)n64;
    for (size_t i=0;i<n;i++) { x[i]=input[3+2*i]; y[i]=input[4+2*i]; if (x[i] < -1000000 || x[i] > 1000000 || y[i] < -1000000 || y[i] > 1000000) return -1; labels[i]=-1; }
    if (!output || capacity < n) return -2;
    int64_t eps2=eps*eps, next=0;
    for (size_t i=0;i<n;i++) {
        if (labels[i] >= 0) continue;
        size_t count=0; for(size_t j=0;j<n;j++){int64_t dx=x[i]-x[j],dy=y[i]-y[j]; if(dx*dx+dy*dy<=eps2) count++;}
        if(count<(size_t)min_pts) continue;
        int64_t cluster=next++; labels[i]=cluster;
        size_t queue[MAX_POINTS], head=0, tail=0; uint8_t queued[MAX_POINTS]={0}; for(size_t j=0;j<n;j++){int64_t dx=x[i]-x[j],dy=y[i]-y[j]; if(dx*dx+dy*dy<=eps2){queue[tail++]=j;queued[j]=1;}}
        while(head<tail){size_t q=queue[head++]; if(labels[q]>=0 && labels[q]!=cluster) continue; labels[q]=cluster; if(expanded[q]) continue; expanded[q]=1;
            size_t nc=0; for(size_t j=0;j<n;j++){int64_t dx=x[q]-x[j],dy=y[q]-y[j]; if(dx*dx+dy*dy<=eps2) nc++;}
            if(nc>=(size_t)min_pts) for(size_t j=0;j<n;j++){int64_t dx=x[q]-x[j],dy=y[q]-y[j]; if(dx*dx+dy*dy<=eps2 && labels[j]<0 && !queued[j]){queue[tail++]=j;queued[j]=1;}}
        }
    }
    for(size_t i=0;i<n;i++) output[i]=(uint8_t)(labels[i]<0?0:labels[i]+1);
    return (int64_t)n;
}
