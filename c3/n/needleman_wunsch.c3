module needleman_wunsch;
const usz MAX_LEN=128;const long INVALID=-9223372036854775808L;
fn long needleman_wunsch(long* v,usz n) @export("needleman_wunsch"){
 if(v==null||n<5||n>261)return INVALID;long a=v[0],b=v[1],match=v[2],mismatch=v[3],gap=v[4];
 if(a<0||a>128||b<0||b>128||match<0||match>10||mismatch< -10||mismatch>0||gap< -10||gap>0||n!=5+(usz)a+(usz)b)return INVALID;
 for(usz i=0;i<(usz)(a+b);i++)if(v[5+i]<65||v[5+i]>90)return INVALID;
 long[129] dp;for(usz j=0;j<=(usz)b;j++)dp[j]=(long)j*gap;
 for(usz i=1;i<=(usz)a;i++){long diagonal=dp[0];dp[0]=(long)i*gap;for(usz j=1;j<=(usz)b;j++){long old=dp[j];long score=v[5+i-1]==v[5+(usz)a+j-1]?match:mismatch;long x=diagonal+score,y=old+gap,z=dp[j-1]+gap;dp[j]=x>y?(x>z?x:z):(y>z?y:z);diagonal=old;}}return dp[(usz)b];
}
