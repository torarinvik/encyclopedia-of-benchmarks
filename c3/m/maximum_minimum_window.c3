module maximum_minimum_window;
fn void store(long value, char* output, usz pos) { ulong bits = (ulong)value; for (usz b=0;b<8;b++) output[pos+b]=(char)((bits>>(8*b))&255); }
fn long maximum_minimum_window(long* input, usz length, char* output, usz capacity) @export("maximum_minimum_window") {
 if(input==null||length<2)return -2;long n0=input[0];if(n0<1||n0>256||length!=(usz)n0+1)return -2;usz n=(usz)n0;
 for(usz i=0;i<n;i++)if(input[i+1]<0||input[i+1]>1000000)return -2;if(output==null||capacity<n*8)return -3;
 usz[256] stack; usz top=0; long[256] left; long[256] right; long[257] ans;
 for(usz i=0;i<n;i++){while(top>0&&input[stack[top-1]+1]>=input[i+1])top--;left[i]=top>0?(long)stack[top-1]:-1;stack[top]=i;top++;}
 top=0;usz ii=n;while(ii>0){ii--;while(top>0&&input[stack[top-1]+1]>=input[ii+1])top--;right[ii]=top>0?(long)stack[top-1]:n;stack[top]=ii;top++;}
 for(usz i=0;i<n;i++){usz size=(usz)(right[i]-left[i]-1);if(ans[size]<input[i+1])ans[size]=input[i+1];}usz k=n;while(k>1){k--;if(ans[k]<ans[k+1])ans[k]=ans[k+1];}
 for(usz i=1;i<=n;i++)store(ans[i],output,(i-1)*8);return (long)n;
}
