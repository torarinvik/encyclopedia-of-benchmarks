#include <cstddef>
#include <cstdint>
#include <vector>
#include <stdbool.h>

extern "C" int64_t detecting_english_programmatically(const int64_t *a, size_t n) {
    if (!a || n < 1 || n > 172) return -1;
    size_t p=0; int64_t count=a[p++];
    if(count<0||count>8)return -1;
    size_t starts[8], lens[8];
    for(int64_t w=0;w<count;++w){
        if(p>=n)return -1; int64_t l=a[p++]; if(l<1||l>12||p+(size_t)l>n)return -1;
        starts[w]=p;lens[w]=(size_t)l;
        for(size_t j=0;j<lens[w];++j)if(a[p+j]<65||a[p+j]>90)return -1;
        if(w){size_t k=0;while(k<lens[w-1]&&k<lens[w]&&a[starts[w-1]+k]==a[p+k])++k;
            if(k==lens[w-1]&&k==lens[w])return -1;
            if(k==lens[w-1]&&k<lens[w]){} else if(k<lens[w-1]&&k<lens[w]&&a[starts[w-1]+k]>a[p+k])return -1;
            else if(k<lens[w-1]&&k==lens[w])return -1;
        }
        p+=(size_t)l;
    }
    if(p>=n)return -1;int64_t m=a[p++];if(m<1||m>64||p+(size_t)m+2!=n)return -1;size_t ms=p;
    for(size_t i=0;i<(size_t)m;++i)if(a[ms+i]<0||a[ms+i]>127)return -1;p+=(size_t)m;
    int64_t wp=a[p++],lp=a[p++];if(wp<0||wp>100||lp<0||lp>100)return -1;
    int64_t retained=0,tokens=0,hits=0;size_t i=0;std::vector<int64_t> token;
    while(i<=(size_t)m){int64_t c=i<(size_t)m?a[ms+i]:32;bool letter=(c>=65&&c<=90)||(c>=97&&c<=122);bool ws=c==9||c==10||c==32;
        if(i<(size_t)m&&(letter||ws))++retained;if(letter){token.push_back(c>=97?c-32:c);++i;continue;}if(!ws){++i;continue;}if(token.empty()){++i;continue;}
        ++tokens;for(int64_t w=0;w<count;++w){if(lens[w]!=token.size())continue;size_t k=0;while(k<token.size()&&a[starts[w]+k]==token[k])++k;if(k==token.size()){++hits;break;}}token.clear();++i;
    }
    return tokens!=0&&hits*100>=wp*tokens&&retained*100>=lp*m;
}
