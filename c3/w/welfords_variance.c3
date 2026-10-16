module welfords_variance;
const usz MAX_LENGTH=64;const long MAX_ABS_VALUE=1000000;const double INVALID_RESULT=-1.0e300;
fn double welfords_variance(long* values,usz length) @export("welfords_variance"){
 if(values==null||length<2||length>MAX_LENGTH)return INVALID_RESULT;double mean=0.0;double m2=0.0;for(usz i=0;i<length;i++){long x=values[i];if(x < -MAX_ABS_VALUE||x>MAX_ABS_VALUE)return INVALID_RESULT;double delta=(double)x-mean;mean+=delta/(double)(i+1);m2+=delta*((double)x-mean);}return m2/(double)(length-1);
}
