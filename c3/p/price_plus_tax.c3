module price_plus_tax;
const long SCALE=1000000;
const long MAX_PRICE_MICRO=1000000000000;
const long MAX_TAX_RATE_MICRO=1000000;
const usz MAX_INPUT_LENGTH=3;
const double INVALID_RESULT=-1.0e300;
fn double price_plus_tax(long* values,usz length) @export("price_plus_tax") {
 if(values==null||length!=2||length>MAX_INPUT_LENGTH)return INVALID_RESULT;
 long price_micro=values[0],tax_rate_micro=values[1];
 if(price_micro<0||price_micro>MAX_PRICE_MICRO||tax_rate_micro<0||tax_rate_micro>MAX_TAX_RATE_MICRO)return INVALID_RESULT;
 double price=(double)price_micro/(double)SCALE;
 double tax_rate=(double)tax_rate_micro/(double)SCALE;
 return price*(1.0+tax_rate);
}
