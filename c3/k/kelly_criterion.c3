module kelly_criterion;
const long SCALE=1000000;
const long MIN_PROBABILITY_MICRO=1;
const long MAX_PROBABILITY_MICRO=999999;
const long MIN_RATIO_MICRO=1000;
const long MAX_RATIO_MICRO=100000000;
const usz MAX_INPUT_LENGTH=3;
const double INVALID_RESULT=-1.0e300;
fn double kelly_criterion(long* values,usz length) @export("kelly_criterion") {
 if(values==null||length!=2||length>MAX_INPUT_LENGTH)return INVALID_RESULT;
 long probability_micro=values[0],ratio_micro=values[1];
 if(probability_micro<MIN_PROBABILITY_MICRO||probability_micro>MAX_PROBABILITY_MICRO||ratio_micro<MIN_RATIO_MICRO||ratio_micro>MAX_RATIO_MICRO)return INVALID_RESULT;
 double win_probability=(double)probability_micro/(double)SCALE;
 double win_loss_ratio=(double)ratio_micro/(double)SCALE;
 double loss_probability=1.0-win_probability;
 return (win_probability*win_loss_ratio-loss_probability)/win_loss_ratio;
}
