module decisions_convolutions;

const usz MAX_DECISIONS = 64;
const usz MAX_CRITERIA = 16;
const long MAX_VALUE = 100000;

fn long decisions_convolutions(long* input, usz length) @export("decisions_convolutions") {
    if (input == null || length < 3) return -1;
    long method=input[0], n_arg=input[1], m_arg=input[2];
    if ((method != 0 && method != 1) || n_arg < 1 || n_arg > 64 || m_arg < 1 || m_arg > 16) return -1;
    usz n=(usz)n_arg, m=(usz)m_arg;
    if (length != 3 + m + n*m) return -1;
    for (usz j=0;j<m;j++) if (input[3+j] < -MAX_VALUE || input[3+j] > MAX_VALUE) return -1;
    for (usz i=0;i<n*m;i++) if (input[3+m+i] < -MAX_VALUE || input[3+m+i] > MAX_VALUE) return -1;
    long best_score=0; usz best_index=0;
    for (usz i=0;i<n;i++) {
        long score=0;
        for (usz j=0;j<m;j++) {
            long product=input[3+m+i*m+j]*input[3+j];
            if (method==0) score+=product;
            else if (j==0 || product<score) score=product;
        }
        if (i==0 || score>best_score) { best_score=score; best_index=i; }
    }
    return (long)best_index;
}
