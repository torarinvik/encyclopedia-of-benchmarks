module palindrome_with_stack;
fn long palindrome_with_stack(long* v,usz n) @export("palindrome_with_stack"){if(v==null||n<1||n>129||v[0]<0||v[0]>128||n!=(usz)v[0]+1)return -1;usz len=(usz)v[0];char[128] stack;for(usz i=0;i<len;i++){long x=v[i+1];if(x<0||x>127)return -1;char c=(char)x;if(c>='A'&&c<='Z')c+=32;stack[i]=c;}for(usz i=0;i<len;i++)if(stack[i]!=stack[len-1-i])return 0;return 1;}
