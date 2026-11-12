module graphai_ggnn_message_update;
import std::math;

fn long graphai_ggnn_message_update(double* input, usz length, double* output,
                                    usz capacity) @export("graphai_ggnn_message_update") {
    const usz N=8, M=24, D=4, MAX_PARSEABLE=453;
    if (input==null || length<3 || length>MAX_PARSEABLE) return -1;
    for (usz q=0; q<length; q++) if (!math.is_finite(input[q])) return -1;
    double nv=input[0], mv=input[1], dv=input[2];
    if (nv!=(double)(long)nv || mv!=(double)(long)mv || dv!=(double)(long)dv ||
        nv<1 || nv>N || mv<0 || mv>M || dv<1 || dv>D) return -1;
    usz n=(usz)nv, m=(usz)mv, d=(usz)dv;
    if (length!=4+n+m+n*d+6*n*n) return -1;
    usz row_at=3, col_at=row_at+n+1, h_at=col_at+m;
    usz wz_at=h_at+n*d, wr_at=wz_at+n*n, wc_at=wr_at+n*n;
    usz uz_at=wc_at+n*n, ur_at=uz_at+n*n, uc_at=ur_at+n*n;
    if (input[row_at]!=0 || input[col_at-1]!=(double)m) return -1;
    usz row[N+1]={0}, col[M]={0};
    for (usz i=0; i<=n; i++) {
        double x=input[row_at+i];
        if (x!=(double)(long)x || x<0 || x>m) return -1;
        row[i]=(usz)x;
        if (i>0 && row[i]<row[i-1]) return -1;
    }
    for (usz e=0; e<m; e++) {
        double x=input[col_at+e];
        if (x!=(double)(long)x || x<0 || x>=n) return -1;
        col[e]=(usz)x;
    }
    for (usz q=h_at; q<wz_at; q++) if (input[q] < -1 || input[q] > 1) return -1;
    for (usz q=wz_at; q<length; q++) if (input[q] < -0.25 || input[q] > 0.25) return -1;
    usz required=n*d;
    if (output==null || capacity<required) return -2;
    double agg[N*D]={0}, update[N*D]={0}, reset[N*D]={0};
    double candidate[N*D]={0}, staged[N*D]={0};
    for (usz v=0; v<n; v++) for (usz e=row[v]; e<row[v+1]; e++)
        for (usz f=0; f<d; f++) agg[v*d+f]+=input[h_at+col[e]*d+f];
    for (usz v=0; v<n; v++) for (usz f=0; f<d; f++) {
        double wz=0, wr=0, uz=0, ur=0;
        for (usz k=0; k<n; k++) {
            usz a=v*n+k, b=k*d+f;
            wz+=input[wz_at+a]*agg[b]; wr+=input[wr_at+a]*agg[b];
            uz+=input[uz_at+a]*input[h_at+b]; ur+=input[ur_at+a]*input[h_at+b];
        }
        usz at=v*d+f;
        update[at]=1.0/(1.0+math.exp(-(wz+uz)));
        reset[at]=1.0/(1.0+math.exp(-(wr+ur)));
    }
    for (usz v=0; v<n; v++) for (usz f=0; f<d; f++) {
        double from_graph=0, from_state=0;
        for (usz k=0; k<n; k++) {
            usz a=v*n+k, b=k*d+f;
            from_graph+=input[wc_at+a]*agg[b];
            from_state+=input[uc_at+a]*(reset[b]*input[h_at+b]);
        }
        usz at=v*d+f;
        double x=from_graph+from_state;
        candidate[at]=2.0/(1.0+math.exp(-2.0*x))-1.0;
        staged[at]=(1.0-update[at])*input[h_at+at]+update[at]*candidate[at];
    }
    for (usz q=0; q<required; q++) output[q]=staged[q];
    return (long)required;
}
