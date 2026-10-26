module count_min_sketch_affine;
const PRIME: long = 2147483647;

fn void put_i64_le(char* out, usz off, long value) {
    ulong bits = (ulong)value;
    for (usz b=0;b<8;b++) { out[off+b]=(char)(bits & 255); bits >>= 8; }
}

fn long count_min_sketch_affine(long* input, usz length, char* output, usz capacity)
    @export("count_min_sketch_affine") {
    if (input==null || length<3 || length>59) return -1;
    long d0=input[0], w0=input[1], ops0=input[2];
    if (d0<1 || d0>4 || w0<1 || w0>8 || ops0<0 || ops0>16) return -1;
    usz d=(usz)d0, w=(usz)w0, ops=(usz)ops0, start=3+2*d;
    if (length!=start+3*ops) return -1;
    long[4] a={0}, b={0};
    for (usz r=0;r<d;r++) { a[r]=input[3+2*r]; b[r]=input[4+2*r]; if (a[r]<1 || a[r]>=PRIME || b[r]<0 || b[r]>=PRIME) return -1; }
    usz queries=0;
    for (usz op=0;op<ops;op++) {
        long kind=input[start+3*op], key=input[start+3*op+1], weight=input[start+3*op+2];
        if (key<0 || key>1000000) return -1;
        if (kind==0) { if (weight<1 || weight>1000000) return -1; }
        else if (kind==1) { if (weight!=0) return -1; queries++; }
        else return -1;
    }
    long[4][8] table={0}; long[16] staged={0}; usz count=0;
    for (usz op=0;op<ops;op++) {
        long kind=input[start+3*op], key=input[start+3*op+1], weight=input[start+3*op+2];
        usz[4] slot={0};
        for (usz r=0;r<d;r++) slot[r]=(usz)(((a[r]*key+b[r])%PRIME)%(long)w);
        if (kind==0) { for (usz r=0;r<d;r++) table[r][slot[r]]+=weight; }
        else { long minimum=table[0][slot[0]]; for (usz r=1;r<d;r++) if (table[r][slot[r]]<minimum) minimum=table[r][slot[r]]; staged[count]=minimum; count++; }
    }
    usz required=queries*8;
    if (capacity<required || (required>0 && output==null)) return -2;
    for (usz i=0;i<count;i++) put_i64_le(output,8*i,staged[i]);
    return (long)required;
}
