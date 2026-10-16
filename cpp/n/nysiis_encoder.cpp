#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

static bool vowel(char c) { return c=='A'||c=='E'||c=='I'||c=='O'||c=='U'; }
static void replace_at(std::string &s, std::size_t i, const char *from, const char *to) { s.replace(i, std::char_traits<char>::length(from), to); }
static void nysiis_prefix(std::string &s) {
    const char *from[]={"MAC","KN","K","PH","PF","SCH"}, *to[]={"MCC","NN","C","FF","FF","SSS"};
    for (std::size_t i=0;i<6;i++) if (s.rfind(from[i],0)==0) { replace_at(s,0,from[i],to[i]); return; }
}
static void nysiis_suffix(std::string &s) {
    const char *from[]={"EE","IE","DT","RT","NT","ND"}, *to[]={"Y","Y","D","D","D","D"};
    for (std::size_t i=0;i<6;i++) { std::string f=from[i]; if (s.size()>=f.size()&&s.compare(s.size()-f.size(),f.size(),f)==0) { s.replace(s.size()-f.size(),f.size(),to[i]); return; } }
}
extern "C" std::int64_t nysiis_encoder(const std::int64_t *v,std::size_t n,std::uint8_t*out,std::size_t cap) {
    if(!v||n<2||n>65||v[0]<1||v[0]>64||n!=static_cast<std::size_t>(v[0])+1)return -1;
    std::string s; for(std::size_t j=0;j<static_cast<std::size_t>(v[0]);j++){int c=(int)v[j+1];if(c>='a'&&c<='z')c-=32;if(c<'A'||c>'Z')return -1;s.push_back((char)c);} if(s.empty())return -1;
    nysiis_prefix(s); nysiis_suffix(s);
    const char *from[]={"EV","E","I","O","U","Q","Z","M","KN","K","SCH","PH"},*to[]={"AF","A","A","A","A","G","S","N","NN","C","SSS","FF"};
    for(std::size_t i=1;i<s.size();i++){
        bool done=false;
        for(std::size_t r=0;r<12;r++){std::string f=from[r];if(i+f.size()<=s.size()&&s.compare(i,f.size(),f)==0){s.replace(i,f.size(),to[r]);done=true;break;}}
        if(done)continue;
        if(s[i]=='H'&&(!vowel(s[i-1])||(i+1<s.size()&&!vowel(s[i+1]))))s[i]=s[i-1];
        else if(s[i]=='W'&&vowel(s[i-1]))s[i]=s[i-1];
    }
    std::string d;for(char c:s)if(d.empty()||d.back()!=c)d.push_back(c);s=d;
    if(!s.empty()&&s.back()=='S')s.pop_back();else if(s.size()>=2&&s.substr(s.size()-2)=="AY")s.replace(s.size()-2,2,"Y");else if(!s.empty()&&s.back()=='A')s.pop_back();
    if(s.size()>cap||(s.size()&&!out))return -2;for(std::size_t i=0;i<s.size();i++)out[i]=(std::uint8_t)s[i];return (std::int64_t)s.size();
}
