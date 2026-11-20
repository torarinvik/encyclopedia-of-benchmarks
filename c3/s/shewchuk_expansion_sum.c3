module shewchuk_expansion_sum;

const usz MAX_TERMS = 16;
const usz MAX_LENGTH = 34;
const long MAX_MANTISSA = 16777216;
const double OUTPUT_SCALE = 1073741824.0;

struct SumPair { double high; double low; }

fn SumPair two_sum(double a, double b) {
    double rounded = a+b;
    double b_virtual = rounded-a;
    double a_virtual = rounded-b_virtual;
    double b_roundoff = b-b_virtual;
    double a_roundoff = a-a_virtual;
    return SumPair{rounded,a_roundoff+b_roundoff};
}

fn usz grow_expansion(double* expansion, usz count, double value, double* grown) {
    double q=value;
    usz grown_count=0;
    for (usz i=0;i<count;i++) {
        SumPair pair=two_sum(q,expansion[i]);
        if (pair.low!=0.0) grown[grown_count++]=pair.low;
        q=pair.high;
    }
    if (q!=0.0 || grown_count==0) grown[grown_count++]=q;
    return grown_count;
}

fn long shewchuk_expansion_sum(long* input, usz length)
        @export("shewchuk_expansion_sum") {
    if (input==null || length<1 || length>MAX_LENGTH) return -1;
    if (input[0]<0 || input[0]>(long)MAX_TERMS) return -1;
    usz n=(usz)input[0];
    if (length!=1+2*n) return -1;

    double[MAX_TERMS+1] expansion;
    double[MAX_TERMS+1] grown;
    usz expansion_count=0;
    for (usz i=0;i<n;i++) {
        long mantissa=input[1+2*i];
        long exponent=input[2+2*i];
        if (mantissa < -MAX_MANTISSA || mantissa > MAX_MANTISSA
                || exponent < -30 || exponent > 0) return -1;
        double value=(double)mantissa;
        for (long shift=0;shift>exponent;shift--) value*=0.5;
        if (value==0.0) continue;
        usz grown_count=grow_expansion(&expansion[0],expansion_count,value,&grown[0]);
        for (usz j=0;j<grown_count;j++) expansion[j]=grown[j];
        expansion_count=grown_count;
    }
    long result=((long)1<<58)+1;
    for (usz i=0;i<expansion_count;i++) result+=(long)(expansion[i]*OUTPUT_SCALE);
    return result;
}
