module connected_components;
const usz MAX_VERTICES=256;

fn void visit(usz vertex, usz n, bool* adjacency, bool* seen) {
    seen[vertex] = true;
    for (usz next = 0; next < n; next++) if (adjacency[vertex * MAX_VERTICES + next] && !seen[next]) visit(next,n,adjacency,seen);
}

fn long connected_components(long* input, usz length) @export("connected_components") {
    if (input == null || length < 2 || input[0] < 0 || input[0] > 256 || input[1] < 0 || input[1] > 512) return -1;
    usz n=(usz)input[0], m=(usz)input[1]; if(length!=2+2*m)return -1;
    bool[65536] adjacency;for(usz i=0;i<65536;i++)adjacency[i]=false;
    for(usz i=0;i<m;i++){long u=input[2+2*i],v=input[3+2*i];if(u<1||u>(long)n||v<1||v>(long)n)return -1;usz a=(usz)(u-1),b=(usz)(v-1);adjacency[a*256+b]=true;adjacency[b*256+a]=true;}
    bool[256] seen;for(usz i=0;i<256;i++)seen[i]=false;long components=0;for(usz i=0;i<n;i++)if(!seen[i]){visit(i,n,&adjacency[0],&seen[0]);components++;}return components;
}
