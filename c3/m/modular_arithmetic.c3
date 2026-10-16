module modular_arithmetic;
fn long modular_arithmetic(long* values, usz length) @export("modular_arithmetic") {
 if(values==null||length!=4)return -1;long op=values[0];long modulus=values[1];long a=values[2];long b=values[3];
 if(op<0||op>2||modulus<1||modulus>1000000||a<0||a>=modulus||b<0||b>=modulus)return -1;
 if(op==0)return ((a%modulus)+(b%modulus))%modulus;
 if(op==1)return ((a%modulus)-(b%modulus)+modulus)%modulus;
 return ((a%modulus)*(b%modulus))%modulus;
}
