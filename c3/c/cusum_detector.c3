module cusum_detector;
const usz MAX_N = 128;
fn void put_i64_le(long value, char* output, usz offset) {
    ulong bits = (ulong)value;
    for (usz b=0;b<8;b++) { output[offset+b]=(char)(bits & 255); bits >>= 8; }
}
fn long cusum_detector(long* input, usz length, char* output, usz capacity) @export("cusum_detector") {
    if (input==null || length<5 || input[0]<0 || input[0]>MAX_N) return -1;
    usz n=(usz)input[0]; if (length!=n+5) return -1;
    long target=input[1]; long sigma=input[2]; long allowance=input[3]; long threshold=input[4];
    if (target < -1000 || target > 1000 || sigma < 1 || sigma > 1000 || allowance < 0 || allowance > 1000 || threshold < 1 || threshold > 1000) return -1;
    for (usz i=0;i<n;i++) if (input[5+i] < -1000 || input[5+i] > 1000) return -1;
    if (capacity<n*8 || (n>0 && output==null)) return -2;
    double upper=0.0; double lower=0.0;
    for (usz i=0;i<n;i++) {
        double z=((double)input[5+i]-(double)target)/(double)sigma;
        upper=upper+z-(double)allowance; if (upper<0.0) upper=0.0;
        lower=lower-z-(double)allowance; if (lower<0.0) lower=0.0;
        long signal=0;
        if (upper>(double)threshold) signal=1; else if (lower>(double)threshold) signal=-1;
        if (signal!=0) { upper=0.0; lower=0.0; }
        put_i64_le(signal,output,i*8);
    }
    (n*8).long()
}
