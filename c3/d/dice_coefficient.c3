module dice_coefficient;
extern fn double floor(double value);
const usz MAX_STRING_LENGTH=128;
const usz ALPHABET_SIZE=95;
const double INVALID_RESULT=-1.0e300;

fn double dice_coefficient(long* values, usz length) @export("dice_coefficient") {
    if (values==null || length<2) return INVALID_RESULT;
    long la_raw=values[0]; long lb_raw=values[1];
    if (la_raw<0 || la_raw>(long)MAX_STRING_LENGTH || lb_raw<0 || lb_raw>(long)MAX_STRING_LENGTH) return INVALID_RESULT;
    usz la=(usz)la_raw; usz lb=(usz)lb_raw;
    if (length!=2+la+lb) return INVALID_RESULT;
    for (usz i=0;i<la+lb;i++) if (values[2+i]<32 || values[2+i]>126) return INVALID_RESULT;
    bool equal=la==lb;
    for (usz i=0;equal && i<la;i++) if (values[2+i]!=values[2+la+i]) equal=false;
    if (equal) return 1.0;
    if (la<2 || lb<2) return 0.0;
    bool[9025] present=zeroed;
    for (usz i=0;i+1<la;i++) {
        usz first=(usz)(values[2+i]-32); usz second=(usz)(values[2+i+1]-32);
        present[first*ALPHABET_SIZE+second]=true;
    }
    usz common=0;
    for (usz i=0;i+1<lb;i++) {
        usz first=(usz)(values[2+la+i]-32); usz second=(usz)(values[2+la+i+1]-32);
        if (present[first*ALPHABET_SIZE+second]) common++;
    }
    double denominator=(double)(la-1+lb-1);
    double score=(2.0*(double)common)/denominator;
    return floor(score*100.0)/100.0;
}
