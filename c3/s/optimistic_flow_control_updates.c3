module optimistic_flow_control_updates;
const usz MAX_N = 3; const usz MAX_L = 4; const usz MAX_INPUT = 20; const usz MAX_OUTPUT = 48; const long SCALE = 46656;

fn long gcd64(long a, long b) { while (b != 0) { long r = a % b; a = b; b = r; } return a; }
fn void put64(char* output, usz position, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[position+byte] = (char)(bits & 255); bits >>= 8; }
}

long optimistic_flow_control_updates(long* input, usz length, char* output, usz capacity) @export("optimistic_flow_control_updates") {
    if (input == null || length < 7 || length > MAX_INPUT) return -1;
    long n64=input[0], l64=input[1], mode64=input[2], q64=input[3];
    if (n64 < 2 || n64 > (long)MAX_N || l64 < 1 || l64 > (long)MAX_L || mode64 < 0 || mode64 > 3 || q64 < 1 || q64 > 6) return -1;
    usz n=(usz)n64, links=(usz)l64, mode=(usz)mode64, updates=(usz)q64;
    if (length != 4 + links + n*links) return -1;
    long[MAX_L] cap = zeroed; bool[MAX_N][MAX_L] path = zeroed; long[MAX_N] rate = zeroed;
    for (usz e=0; e<links; e+=1) { cap[e]=input[4+e]; if (cap[e]<1 || cap[e]>16) return -1; }
    for (usz s=0; s<n; s+=1) {
        bool used=false;
        for (usz e=0; e<links; e+=1) {
            long value=input[4+links+s*links+e]; if (value!=0 && value!=1) return -1;
            path[s][e]=value==1; if (value==1) used=true;
        }
        if (!used) return -1;
    }
    usz output_bytes=16*n; if (output==null || capacity<output_bytes) return -2;
    for (usz step=0; step<updates; step+=1) {
        usz session=0;
        if (mode==0) session=step%n;
        else if (mode==1) { for (usz s=1; s<n; s+=1) if (rate[s]<rate[session]) session=s; }
        else if (mode==2) {
            bool found=false;
            for (usz s=0; s<n && !found; s+=1) {
                bool local=true;
                for (usz j=0; j<n && local; j+=1) if (j!=s) {
                    bool shares=false; for (usz e=0; e<links; e+=1) if (path[s][e] && path[j][e]) shares=true;
                    if (shares && (rate[j]<rate[s] || (rate[j]==rate[s] && j<s))) local=false;
                }
                if (local) { session=s; found=true; }
            }
        } else {
            usz chosen_link=links; long best_load=0;
            for (usz e=0; e<links; e+=1) {
                long load=0; bool used=false;
                for (usz s=0; s<n; s+=1) if (path[s][e]) { load+=rate[s]; used=true; }
                if (used && (chosen_link==links || load*cap[chosen_link]>best_load*cap[e])) { chosen_link=e; best_load=load; }
            }
            for (usz s=0; s<n; s+=1) if (path[s][chosen_link]) { session=s; break; }
        }
        long best=0x7fffffffffffffff; usz bottleneck=links;
        for (usz e=0; e<links; e+=1) if (path[session][e]) {
            long fixed=0; usz active=1;
            for (usz j=0; j<n; j+=1) if (j!=session && path[j][e]) { if (rate[j]<=rate[session]) fixed+=rate[j]; else active+=1; }
            long level=rate[session], candidate=level;
            for (usz pass=0; pass<n; pass+=1) {
                long numerator=cap[e]*SCALE-fixed;
                if (numerator<0 || numerator%(long)active!=0) return -1;
                candidate=numerator/(long)active; if (candidate<level) return -1;
                long next=0x7fffffffffffffff;
                for (usz j=0; j<n; j+=1) if (j!=session && path[j][e] && rate[j]>level && rate[j]<next) next=rate[j];
                if (next==0x7fffffffffffffff || candidate<=next) break;
                usz saturated=0; for (usz j=0; j<n; j+=1) if (j!=session && path[j][e] && rate[j]==next) saturated+=1;
                fixed+=(long)saturated*next; active-=saturated; level=next;
            }
            if (candidate<best) { best=candidate; bottleneck=e; }
        }
        if (bottleneck==links) return -1;
        rate[session]=best;
        for (usz j=0; j<n; j+=1) if (j!=session && path[j][bottleneck] && rate[j]>best) rate[j]=best;
    }
    char[MAX_OUTPUT] staged=zeroed;
    for (usz s=0; s<n; s+=1) { long g=gcd64(rate[s],SCALE); put64(&staged[0],16*s,rate[s]/g); put64(&staged[0],16*s+8,SCALE/g); }
    for (usz b=0; b<output_bytes; b+=1) output[b]=staged[b];
    return (long)output_bytes;
}
