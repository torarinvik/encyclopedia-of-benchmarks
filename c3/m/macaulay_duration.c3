module macaulay_duration;
extern fn double pow(double base, double exponent);
const long SCALE=1000000;
const long MAX_FACE_VALUE_MICRO=1000000000000;
const long MAX_RATE_MICRO=1000000;
const long MAX_PERIODS=64;
const usz MAX_INPUT_LENGTH=5;
const double INVALID_RESULT=-1.0e300;
fn double macaulay_duration(long* values,usz length) @export("macaulay_duration") {
 if(values==null||length!=4||length>MAX_INPUT_LENGTH)return INVALID_RESULT;
 long face_micro=values[0],coupon_micro=values[1],periods=values[2],yield_micro=values[3];
 if(face_micro<1||face_micro>MAX_FACE_VALUE_MICRO||coupon_micro<0||coupon_micro>MAX_RATE_MICRO||periods<1||periods>MAX_PERIODS||yield_micro<1||yield_micro>MAX_RATE_MICRO)return INVALID_RESULT;
 double face_value=(double)face_micro/(double)SCALE;
 double coupon_rate=(double)coupon_micro/(double)SCALE;
 double yield_rate=(double)yield_micro/(double)SCALE;
 double total_present_value=0.0,total_time_weighted_value=0.0;
 for(long period=1;period<=periods;period++){
  double cash_flow=face_value*coupon_rate+(period==periods?face_value:0.0);
  double time_weighted_value=((double)period*cash_flow)/pow(1.0+yield_rate,(double)period);
  total_time_weighted_value+=time_weighted_value;
  double present_value=cash_flow/pow(1.0+yield_rate,(double)period);
  total_present_value+=present_value;
 }
 return total_time_weighted_value/total_present_value;
}
