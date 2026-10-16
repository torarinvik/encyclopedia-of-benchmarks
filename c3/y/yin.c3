module yin;

const double INVALID_RESULT = -1.0e300;
const long MAX_SAMPLES = 256;

fn double yin(long* input, usz length) @export("yin") {
    if (input == null || length < 7 || length > 261) return INVALID_RESULT;
    long count_value=input[0]; long rate=input[1]; long min_hz=input[2]; long max_hz=input[3]; long threshold=input[4];
    if(count_value<2||count_value>MAX_SAMPLES||length!=5+(usz)count_value||rate<1||rate>192000||min_hz<1||max_hz<=min_hz||max_hz>rate/2||threshold<1||threshold>999999)return INVALID_RESULT;
    usz count=(usz)count_value;
    for(usz i=0;i<count;i++)if(input[5+i]<-32768||input[5+i]>32767)return INVALID_RESULT;
    long min_lag_value=rate/max_hz; long max_lag_value=rate/min_hz;
    long allowed=count-1<64?(long)(count-1):64;
    if(min_lag_value<1||min_lag_value>max_lag_value||max_lag_value>allowed)return INVALID_RESULT;
    usz min_lag=(usz)min_lag_value; usz max_lag=(usz)max_lag_value;
    double[65] cmndf; for(usz i=0;i<65;i++)cmndf[i]=1.0;
    double running=0.0;
    for(usz lag=1;lag<=max_lag;lag++){
        double sum=0.0;
        for(usz i=0;i<count-lag;i++){double delta=(double)input[5+i]-(double)input[5+i+lag];sum+=delta*delta;}
        running+=sum; cmndf[lag]=sum*(double)lag/(running==0.0?1.0e-10:running);
    }
    double threshold_f=(double)threshold/1000000.0;
    usz lag=min_lag; while(lag<=max_lag&&!(cmndf[lag]<threshold_f))lag++;
    if(lag>max_lag)return INVALID_RESULT;
    while(lag<max_lag&&cmndf[lag+1]<cmndf[lag])lag++;
    usz left=lag>1?lag-1:lag; usz right=lag<max_lag?lag+1:lag;
    double denominator=cmndf[left]-2.0*cmndf[lag]+cmndf[right];
    double offset=denominator==0.0?0.0:(cmndf[left]-cmndf[right])/(2.0*denominator);
    double refined=(double)lag+offset; if(!(refined>0.0))return INVALID_RESULT;
    return (double)rate/refined;
}
