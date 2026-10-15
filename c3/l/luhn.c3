module luhn;
fn long luhn_validate_impl(long* input,usz length){
 if(input==null||length<1)return -1;long n=input[0];if(n<2||n>64||n%2!=0||length!=(usz)(n+1))return -1;
 long sum=0;for(usz i=0;i<(usz)n;i++){long d=input[i+1];if(d<0||d>9)return -1;if(i%2==0){d*=2;if(d>9)d-=9;}sum+=d;}return sum%10==0?1:0;
}
fn long luhn_validate(long* input,usz length) @export("luhn_validate"){return luhn_validate_impl(input,length);}
