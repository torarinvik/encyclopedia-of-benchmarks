module ansibench_dhrystone;
// Dhrystone 2.1 bounded core profile. Upstream public-domain notice in package LICENSE.
import "core:c";
const int I1=0, I2=1, I3=2, I4=3, I5=4;
struct Record { int ptr; int discr; int enum_comp; int int_comp; char[31] str; }
struct State { int int_glob; int bool_glob; int ch1; int ch2; int[50] a1; int[50][50] a2; Record[2] rec; }
fn void cp(char* d, const char* s) { usz i=0; do { d[i]=s[i]; } while(s[i++]!=0); }
fn int cmp(const char* a,const char* b) { for(usz i=0;i<31;i++){int x=(uint8_t)a[i],y=(uint8_t)b[i];if(x!=y)return x<y?-1:1;if(x==0)return 0;}return 0; }
fn int f1(State* s,int a,int b){if(a!=b)return I1;s.ch1=a;return I2;}
fn bool f3(int e){return e==I3;}
fn void p7(int a,int b,int* out){*out=b+(a+2);}
fn void p6(State* s,int v,int* out){*out=v;if(!f3(v))*out=I4;switch(v){case I1:*out=I1;break;case I2:*out=s.int_glob>100?I1:I4;break;case I3:*out=I2;break;case I4:break;case I5:*out=I3;break;}}
fn void p3(State* s,int* ref){if(s.rec[0].ptr>=0)*ref=s.rec[0].ptr;p7(10,s.int_glob,&s.rec[0].int_comp);}
fn void p1(State* s){int next=s.rec[0].ptr;s.rec[next]=s.rec[0];s.rec[0].int_comp=5;s.rec[next].int_comp=s.rec[0].int_comp;s.rec[next].ptr=s.rec[0].ptr;p3(s,&s.rec[next].ptr);if(s.rec[next].discr==I1){s.rec[next].int_comp=6;p6(s,s.rec[0].enum_comp,&s.rec[next].enum_comp);s.rec[next].ptr=s.rec[0].ptr;p7(s.rec[next].int_comp,10,&s.rec[next].int_comp);}else s.rec[0]=s.rec[next];}
fn void p2(State* s,int* v){int loc=*v+10,e=0;do{if(s.ch1=='A'){loc-=1;*v=loc-s.int_glob;e=I1;}else e=I2;}while(e!=I1);}
fn void p4(State* s){int local=s.ch1=='A'?1:0;s.bool_glob=local|s.bool_glob;s.ch2='B';}
fn void p5(State* s){s.ch1='A';s.bool_glob=0;}
fn void p8(State* s,int a,int b){int loc=a+5;s.a1[loc]=b;s.a1[loc+1]=s.a1[loc];s.a1[loc+30]=loc;for(int i=loc;i<=loc+1;i++)s.a2[loc][i]=loc;s.a2[loc][loc-1]+=1;s.a2[loc+20][loc]=s.a1[loc];s.int_glob=5;}
fn bool f2(State* s,const char* a,const char* b){int loc=2,ch=0;while(loc<=2)if(f1(s,a[loc],b[loc+1])==I1){ch='A';loc++;}if(ch>='W'&&ch<'Z')loc=7;if(ch=='R')return true;if(cmp(a,b)>0){loc+=7;s.int_glob=loc;return true;}return false;}
fn void put64le(char* out,usz* at,ulong v){for(uint i=0;i<8;i++)out[(*at)++]=(char)(v>>(8*i));}
fn long ansibench_dhrystone(long* input,usz length,char* output,usz capacity) @export("ansibench_dhrystone") {
 if(input==null||length!=1||input[0]<1||input[0]>8)return -1;
 State s={};s.rec[0].ptr=1;s.rec[0].discr=I1;s.rec[0].enum_comp=I3;s.rec[0].int_comp=40;cp(&s.rec[0].str[0],"DHRYSTONE PROGRAM, SOME STRING");
 char[31] str1={};char[31] str2={};cp(&str1[0],"DHRYSTONE PROGRAM, 1'ST STRING");s.a2[8][7]=10;
 int a=0,b=0,c=0,e=0,f2false=0;
 for(int run=1;run<=input[0];run++){p5(&s);p4(&s);a=2;b=3;cp(&str2[0],"DHRYSTONE PROGRAM, 2'ND STRING");e=I2;f2false=f2(&s,&str1[0],&str2[0])?0:1;while(a<b){c=5*a-b;p7(a,b,&c);a++;}p8(&s,a,c);p1(&s);for(int ch='A';ch<=s.ch2;ch++)if(e==f1(&s,ch,'C')){p6(&s,I1,&e);cp(&str2[0],"DHRYSTONE PROGRAM, 3'RD STRING");b=run;s.int_glob=run;}b=b*a;a=b/c;b=7*(b-c)-a;p2(&s,&a);}
 if(output==null||capacity<19)return -2;char[19] staged={};int values[19]={s.int_glob,s.bool_glob,s.ch1,s.ch2,s.a1[8],s.a2[8][7],s.rec[0].discr,s.rec[0].enum_comp,s.rec[0].int_comp,s.rec[0].ptr,s.rec[1].discr,s.rec[1].enum_comp,s.rec[1].int_comp,s.rec[1].ptr,a,b,c,e,f2false};for(usz i=0;i<19;i++)staged[i]=(char)values[i];for(usz i=0;i<19;i++)output[i]=staged[i];return 19;
}
