module bkp_speed_scaling_trace;

const usz MAX_JOBS = 4;
const usz MAX_SAMPLES = 8;
const usz MAX_INPUT = 31;
const usz MAX_OUTPUT = 136;
const long E_NUM = 271828, E_DEN = 100000, EM1_NUM = 171828;

fn long gcd64(long a, long b) {
    while (b != 0) { long r = a % b; a = b; b = r; }
    return a < 0 ? -a : a;
}
fn void consider(long* release, long* deadline, long* work, usz n,
    long t, long x_num, long x_den, long* best_num, long* best_den) {
    long delta = x_num - t*x_den;
    if (delta <= 0) return;
    long left = E_NUM*t*x_den - EM1_NUM*x_num;
    long total = 0;
    for (usz j=0; j<n; j+=1)
        if (release[j] <= t && left <= E_DEN*x_den*release[j] && deadline[j]*x_den <= x_num) total += work[j];
    long num = total*x_den;
    if (num*(*best_den) > (*best_num)*delta) { *best_num=num; *best_den=delta; }
}
fn void put64(char* output, usz at, long value) {
    ulong bits=(ulong)value;
    for (usz b=0; b<8; b+=1) { output[at+b]=(char)(bits&255); bits >>= 8; }
}

fn long bkp_speed_scaling_trace(long* input, usz length, char* output, usz capacity)
        @export("bkp_speed_scaling_trace") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n64=input[0], samples64=input[1];
    if (n64 < 1 || n64 > (long)MAX_JOBS || samples64 < 1 || samples64 > (long)MAX_SAMPLES) return -1;
    usz n=(usz)n64, samples=(usz)samples64;
    if (length != 2+3*n+2*samples) return -1;
    long[MAX_JOBS] release=zeroed, deadline=zeroed, work=zeroed;
    for (usz j=0; j<n; j+=1) {
        release[j]=input[2+3*j]; deadline[j]=input[3+3*j]; work[j]=input[4+3*j];
        if (release[j] < 0 || release[j] >= deadline[j] || deadline[j] > 8 || work[j] < 1 || work[j] > 8) return -1;
    }
    long[1+2*MAX_SAMPLES] values=zeroed;
    values[0]=samples64;
    for (usz s=0; s<samples; s+=1) {
        long t=input[2+3*n+2*s], mask=input[3+3*n+2*s];
        if (t < 0 || t > 8 || mask < 0 || mask >= (1L << n)) return -1;
        for (usz j=0; j<n; j+=1) if ((mask & (1L << j)) != 0 && release[j] > t) return -1;
        long best_num=0, best_den=1;
        if (mask != 0) for (usz j=0; j<n; j+=1) if (release[j] <= t) {
            if (deadline[j] > t) consider(&release[0],&deadline[0],&work[0],n,t,deadline[j],1,&best_num,&best_den);
            if (release[j] < t) consider(&release[0],&deadline[0],&work[0],n,t,E_NUM*t-E_DEN*release[j],EM1_NUM,&best_num,&best_den);
        }
        long g=gcd64(best_num,best_den);
        values[1+2*s]=best_num/g; values[2+2*s]=best_den/g;
    }
    usz bytes=8*(1+2*samples);
    if (output == null || capacity < bytes) return -2;
    char[MAX_OUTPUT] staged=zeroed;
    for (usz i=0; i<1+2*samples; i+=1) put64(&staged[0],8*i,values[i]);
    for (usz i=0; i<bytes; i+=1) output[i]=staged[i];
    return (long)bytes;
}
