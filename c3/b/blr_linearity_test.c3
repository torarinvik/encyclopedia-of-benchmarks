module blr_linearity_test;
const int MAX_N=6;const int MAX_Q=32;const int MAX_INPUT=130;const int MAX_OUTPUT=24;
fn void put_i64(char* out,usz offset,long value){ulong bits=(ulong)value;for(usz i=0;i<8;i++){out[offset+i]=(char)(bits&255);bits>>=8;}}
fn long blr_linearity_test(long* values,usz length,char* output,usz capacity) @export("blr_linearity_test") {
 if(values==null||length<2||length>MAX_INPUT||values[0]<1||values[0]>MAX_N||values[1]<1||values[1]>MAX_Q)return -1;
 int n=(int)values[0],q=(int)values[1];usz domain=(usz)1<<n;if(length!=2+domain+2*q)return -1;
 long* table=values+2;long* tape=table+domain;
 for(usz i=0;i<domain;i++)if(table[i]!=0&&table[i]!=1)return -1;
 for(usz i=0;i<2*q;i++)if(tape[i]<0||(ulong)tape[i]>=domain)return -1;
 usz rounds=0;long accepted=1;
 for(int r=0;r<q;r++){usz x=(usz)tape[2*r],y=(usz)tape[2*r+1];rounds++;if((table[x]^table[y])!=table[x^y]){accepted=0;break;}}
 if(output==null||capacity<MAX_OUTPUT)return -2;char[MAX_OUTPUT] staged={};put_i64(staged,0,accepted);put_i64(staged,8,(long)rounds);put_i64(staged,16,(long)(3*rounds));for(usz i=0;i<MAX_OUTPUT;i++)output[i]=staged[i];return MAX_OUTPUT;
}
