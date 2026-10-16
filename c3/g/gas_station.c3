module gas_station;
const usz MAX_N=128;
const long MAX_AMOUNT=1000000;
fn long gas_station(long* input, usz length) @export("gas_station") {
    if (input==null || length<1 || input[0]<0 || input[0]>MAX_N) return -2;
    usz n=(usz)input[0]; if (length!=2*n+1) return -2;
    for (usz i=0;i<2*n;i++) if (input[i+1]<0 || input[i+1]>MAX_AMOUNT) return -2;
    long total=0; long current=0; usz start=0;
    for (usz i=0;i<n;i++) {
        long net=input[1+i]-input[1+n+i]; total+=net; current+=net;
        if (current<0) { start=i+1; current=0; }
    }
    if (total<0) return -1;
    return (long)start;
}
