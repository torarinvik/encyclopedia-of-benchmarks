#include <stddef.h>
#include <stdint.h>
#define MAX_BYTES 62
#define MAX_TOKENS 31
#define INVALID -1e300
static int op(int c){return c=='+'||c=='-'||c=='*'||c=='/';}
double prefix_evaluation(const int64_t*v,size_t n){if(!v||n<2||n>MAX_BYTES+1||v[0]<1||v[0]>MAX_BYTES||n!=(size_t)v[0]+1)return INVALID;char tokens[MAX_TOKENS];size_t count=0;int need_token=1;for(size_t i=1;i<n;i++){if(v[i]<0||v[i]>127)return INVALID;int c=(int)v[i];if(c==' '){if(need_token)return INVALID;need_token=1;continue;}if(!(op(c)||(c>='0'&&c<='9'))||!need_token||count>=MAX_TOKENS)return INVALID;tokens[count++]=(char)c;need_token=0;}if(need_token||count==0)return INVALID;double stack[MAX_TOKENS];size_t top=0;for(size_t pos=count;pos>0;pos--){int c=tokens[pos-1];if(c>='0'&&c<='9'){stack[top++]=(double)(c-'0');continue;}if(top<2)return INVALID;double first=stack[--top],second=stack[--top];if(c=='+')stack[top++]=first+second;else if(c=='-')stack[top++]=first-second;else if(c=='*')stack[top++]=first*second;else{if(second==0)return INVALID;stack[top++]=first/second;}}return top==1?stack[0]:INVALID;}
