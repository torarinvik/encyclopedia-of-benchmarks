module damm;
const usz MAX_DIGITS=256;
fn long row_value(long state) { switch(state) {
        case 0: return 317598642L;
        case 1: return 7092154863L;
        case 2: return 4206871359L;
        case 3: return 1750983426L;
        case 4: return 6123045978L;
        case 5: return 3674209581L;
        case 6: return 5869720134L;
        case 7: return 8945362017L;
        case 8: return 9438617205L;
        case 9: return 2581436790L;
        default: return 0L; } }
fn long damm_impl(long* input,usz length) {
 if(input==null||length<3||length>MAX_DIGITS+2)return -1L;
 long mode=input[0],n=input[1];if((mode!=0&&mode!=1)||n<1||n>MAX_DIGITS||length!=(usz)(n+2))return -1L;
 long state=0;for(usz i=0;i<(usz)n;i++){long d=input[i+2];if(d<0||d>9)return -1L;long row=row_value(state);long divisor=1;for(int j=0;j<9-(int)d;j++)divisor*=10;state=(row/divisor)%10;}
 return mode==0 ? (state==0?1L:0L) : state;
}
fn long damm(long* input,usz length) @export("damm") { return damm_impl(input,length); }
