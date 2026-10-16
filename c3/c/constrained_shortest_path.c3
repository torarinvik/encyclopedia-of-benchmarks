module constrained_shortest_path;
const usz MAX_NODES=16; const usz MAX_EDGES=64; const usz MAX_RESOURCE=32;
const long INF=9223372036854775807L;

fn long constrained_shortest_path(long* input, usz length) @export("constrained_shortest_path") {
    if (input==null || length<5) return -2;
    long n_raw=input[0]; long m_raw=input[1]; long start=input[2]; long target=input[3]; long limit_raw=input[4];
    if (n_raw<1 || n_raw>(long)MAX_NODES || m_raw<0 || m_raw>(long)MAX_EDGES || limit_raw<0 || limit_raw>(long)MAX_RESOURCE) return -2;
    usz n=(usz)n_raw; usz m=(usz)m_raw; usz limit=(usz)limit_raw;
    if (length!=5+4*m || start<0 || start>=n_raw || target<0 || target>=n_raw) return -2;
    for (usz e=0;e<m;e++) {
        usz p=5+4*e;
        if (input[p]<0 || input[p]>=n_raw || input[p+1]<0 || input[p+1]>=n_raw || input[p+2]<0 || input[p+2]>1000 || input[p+3]<1 || input[p+3]>(long)MAX_RESOURCE) return -2;
    }
    long[528] dp;
    for (usz r=0;r<=limit;r++) for (usz u=0;u<n;u++) dp[r*16+u]=INF;
    dp[(usz)start]=0;
    for (usz r=0;r<=limit;r++) for (usz u=0;u<n;u++) {
        long current=dp[r*16+u];
        if (current==INF) continue;
        for (usz e=0;e<m;e++) {
            usz p=5+4*e;
            if ((usz)input[p]!=u) continue;
            usz resource=(usz)input[p+3];
            if (r+resource<=limit) {
                usz v=(usz)input[p+1]; long candidate=current+input[p+2];
                usz at=(r+resource)*16+v;
                if (candidate<dp[at]) dp[at]=candidate;
            }
        }
    }
    long answer=INF;
    for (usz r=0;r<=limit;r++) if (dp[r*16+(usz)target]<answer) answer=dp[r*16+(usz)target];
    return answer==INF ? -1 : answer;
}
