module enigma_machine2;
const int MAX_TEXT=12;
const char[26] ROTOR1="EGZWVONAHDCLFQMSIPJBYUKXTR";
const char[26] ROTOR2="FOBHMDKEXQNRAULPGSJVTYICZW";
const char[26] ROTOR3="ZJXESIUQLHAVRMDOYGTNFWPBKC";
fn int mod26(int x){x%=26;return x<0?x+26:x;}
fn int rotor(int which,int x){if(which==0)return ROTOR1[x]-'A';if(which==1)return ROTOR2[x]-'A';return ROTOR3[x]-'A';}
fn int inverse(int which,int x){for(int i=0;i<26;i++)if(rotor(which,i)==x)return i;return 0;}
fn long enigma_machine2(long* a,usz length) @export("enigma_machine2"){
 if(a==null||length<4||length>16)return -1;long n=a[0];if(n<0||n>MAX_TEXT||length!=4+(usz)n)return -1;
 int[3] p;for(int j=0;j<3;j++){if(a[1+j]<1||a[1+j]>26)return -1;p[j]=(int)a[1+j]-1;}
 for(int i=0;i<(int)n;i++)if(a[4+i]<0||a[4+i]>25)return -1;
 long out=0;for(int i=0;i<(int)n;i++){int x=(int)a[4+i];for(int r=0;r<3;r++)x=rotor(r,mod26(x+p[r]));x=mod26(x+13);for(int r=2;r>=0;r--)x=mod26(inverse(r,x)-p[r]);out=out*26+x;p[0]++;if(p[0]==26){p[0]=0;p[1]++;if(p[1]==26){p[1]=0;p[2]=(p[2]+1)%26;}}}return out;
}
