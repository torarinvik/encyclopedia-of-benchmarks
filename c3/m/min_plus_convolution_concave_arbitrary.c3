module min_plus_convolution_concave_arbitrary;

const int MAX_INPUT = 67;
const usz MAX_OUTPUT = 504;

fn void store_i64_le(uint8 *output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte=0; byte<8; byte++) { output[offset+byte]=(uint8)(bits&255ul); bits >>= 8; }
}

fn void block_rows(long *concave, long *arbitrary, long *result,
                   usz x1, usz x2, usz y1, usz y2,
                   usz row1, usz row2, usz q1, usz q2) {
    if (row1 > row2) return;
    usz mid=row1+(row2-row1)/2, x=x1+mid;
    long best=9223372036854775807l; usz best_q=q1;
    for (usz q=q1; q<=q2; q++) {
        usz y=y2-q; long value=arbitrary[y]+concave[x-y];
        if (value<best) {best=value;best_q=q;}
    }
    if (best<result[x]) result[x]=best;
    if (row1<mid) block_rows(concave,arbitrary,result,x1,x2,y1,y2,row1,mid-1,q1,best_q);
    if (mid<row2) block_rows(concave,arbitrary,result,x1,x2,y1,y2,mid+1,row2,best_q,q2);
}

fn void scan_rectangle(long *concave, long *arbitrary, long *result,
                       usz *y_min, usz *y_max, usz x1, usz x2, usz y1, usz y2) {
    for (usz x=x1; x<=x2; x++) {
        usz low=y_min[x]>y1?y_min[x]:y1, high=y_max[x]<y2?y_max[x]:y2;
        if (low>high) continue;
        for (usz y=low; y<=high; y++) { long value=arbitrary[y]+concave[x-y]; if (value<result[x]) result[x]=value; }
    }
}

fn void partition(long *concave, long *arbitrary, long *result,
                  usz *y_min, usz *y_max, usz *x_min, usz *x_max,
                  usz x1, usz x2, usz y1, usz y2) {
    if (x1>x2 || y1>y2) return;
    if (y_max[x1]>=y2 && y1>=y_min[x2]) {
        block_rows(concave,arbitrary,result,x1,x2,y1,y2,0,x2-x1,0,y2-y1); return;
    }
    if ((x2-x1)*(y2-y1)<1000) { scan_rectangle(concave,arbitrary,result,y_min,y_max,x1,x2,y1,y2); return; }
    if (x2-x1>y2-y1) {
        usz mid=(x1+x2)/2, left_y2=y_max[mid]<y2?y_max[mid]:y2;
        if (y1<=left_y2) partition(concave,arbitrary,result,y_min,y_max,x_min,x_max,x1,mid,y1,left_y2);
        usz right_y1=y_min[mid]>y1?y_min[mid]:y1;
        if (right_y1<=y2) partition(concave,arbitrary,result,y_min,y_max,x_min,x_max,mid+1,x2,right_y1,y2);
    } else {
        usz mid=(y1+y2)/2, left_x2=x_max[mid]<x2?x_max[mid]:x2;
        if (x1<=left_x2) partition(concave,arbitrary,result,y_min,y_max,x_min,x_max,x1,left_x2,y1,mid);
        usz right_x1=x_min[mid]>x1?x_min[mid]:x1;
        if (right_x1<=x2) partition(concave,arbitrary,result,y_min,y_max,x_min,x_max,right_x1,x2,mid+1,y2);
    }
}

fn long min_plus_convolution_concave_arbitrary(long *input, usz length, uint8 *output, usz capacity)
    @export("min_plus_convolution_concave_arbitrary") {
    if (input==null || length<4 || length>MAX_INPUT) return -1;
    long n0=input[0],m0=input[1];
    if (n0<1 || n0>32 || m0<1 || m0>32) return -1;
    usz n=(usz)n0,m=(usz)m0;
    if (length!=2+n+m) return -1;
    long[32] concave, arbitrary;
    for (usz i=0;i<n+m;i++) {
        long value=input[2+i]; if (value<0 || value>1000000000) return -1;
        if (i<n) concave[i]=value; else arbitrary[i-n]=value;
    }
    for (usz i=0;i+2<n;i++) if (concave[i+1]-concave[i]<concave[i+2]-concave[i+1]) return -1;
    usz h=n+m-1,bytes=8*h;
    if (bytes>MAX_OUTPUT) return -1;
    if (output==null || capacity<bytes) return -2;
    long[63] result;
    usz[63] y_min,y_max; usz[32] x_min,x_max;
    for (usz x=0;x<h;x++) {y_min[x]=x>=n?x-n+1:0;y_max[x]=x<m?x:m-1;result[x]=9223372036854775807l;}
    for (usz y=0;y<m;y++) {x_min[y]=y;x_max[y]=n-1+y;}
    partition(&concave[0],&arbitrary[0],&result[0],&y_min[0],&y_max[0],&x_min[0],&x_max[0],0,h-1,0,m-1);
    for (usz i=0;i<h;i++) store_i64_le(output,8*i,result[i]);
    return (long)bytes;
}
