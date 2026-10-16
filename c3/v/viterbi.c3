module viterbi;

fn void put_i64(long value, char* out, usz offset) {
    char* bytes = (char*)&value;
    for (usz b=0; b<8; b++) out[offset+b]=bytes[b];
}
fn long viterbi(long* input, usz length, char* output, usz capacity) @export("viterbi") {
    if (input == null || length < 1 || length > 64) return -1;
    for (usz i=0;i<length;i++) if (input[i] < 0 || input[i] > 2) return -1;
    if (output == null || capacity < length*8) return -2;
    double[2] score; score[0]=0.6; score[1]=0.4;
    double[4] trans; trans[0]=0.7; trans[1]=0.3; trans[2]=0.4; trans[3]=0.6;
    double[6] emit; emit[0]=0.5; emit[1]=0.4; emit[2]=0.1; emit[3]=0.1; emit[4]=0.3; emit[5]=0.6;
    score[0] *= emit[input[0]]; score[1] *= emit[3+input[0]];
    usz[128] back;
    for (usz t=1;t<length;t++) {
        double[2] next;
        for (usz s=0;s<2;s++) {
            double a=score[0]*trans[s]*emit[s*3+(usz)input[t]];
            double b=score[1]*trans[2+s]*emit[s*3+(usz)input[t]];
            usz p=b>a?1:0; back[t*2+s]=p; next[s]=p==0?a:b;
        }
        score[0]=next[0]; score[1]=next[1];
    }
    usz state=score[1]>score[0]?1:0; usz[64] path; path[length-1]=state;
    usz t=length; while(t>1) { t--; state=back[t*2+state]; path[t-1]=state; }
    for (usz i=0;i<length;i++) put_i64((long)path[i],output,i*8);
    return (long)(length*8);
}
