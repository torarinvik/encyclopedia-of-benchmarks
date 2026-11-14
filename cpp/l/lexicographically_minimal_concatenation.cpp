// Independent suffix-array/LCP concatenation draft; uncompiled and unrun.
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <numeric>
#include <utility>
#include <vector>

namespace minimal_concat_draft {
struct Word { int start, size; };

struct SuffixLcp {
    std::vector<int> rank, logs;
    std::vector<std::vector<int>> table;
    explicit SuffixLcp(const std::vector<int>& text) {
        const int n=static_cast<int>(text.size());
        std::vector<int> sa(n), next(n), classes=text;
        std::iota(sa.begin(),sa.end(),0);
        for (int step=1; step<n; step*=2) {
            auto key = [&](int i) { return std::pair<int,int>{classes[i], i+step<n ? classes[i+step] : -1}; };
            std::sort(sa.begin(),sa.end(),[&](int a,int b) { return key(a)<key(b); });
            next[sa[0]]=0;
            for (int i=1; i<n; ++i) next[sa[i]]=next[sa[i-1]]+(key(sa[i-1])!=key(sa[i]));
            classes.swap(next);
            if (classes[sa.back()]==n-1) break;
        }
        rank.resize(n);
        for (int i=0; i<n; ++i) rank[sa[i]]=i;
        std::vector<int> lcp(n,0);
        int shared=0;
        for (int i=0; i<n; ++i) {
            int r=rank[i];
            if (r==0) { shared=0; continue; }
            int j=sa[r-1];
            while (i+shared<n && j+shared<n && text[i+shared]==text[j+shared]) ++shared;
            lcp[r]=shared;
            if (shared) --shared;
        }
        logs.resize(n+1,0);
        for (int i=2; i<=n; ++i) logs[i]=logs[i/2]+1;
        table.push_back(std::move(lcp));
        for (int width=2; width<=n; width*=2) {
            int half=width/2;
            std::vector<int> row(n-width+1);
            for (int i=0; i+width<=n; ++i) row[i]=std::min(table.back()[i],table.back()[i+half]);
            table.push_back(std::move(row));
        }
    }
    int common(int a,int b,int limit) const {
        if (a==b) return limit;
        int lo=rank[a], hi=rank[b];
        if (lo>hi) std::swap(lo,hi);
        ++lo;
        const int width=hi-lo+1, level=logs[width];
        return std::min(limit,std::min(table[level][lo],table[level][hi-(1<<level)+1]));
    }
};
}

extern "C" std::int64_t lexicographically_minimal_concatenation(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) {
    using namespace minimal_concat_draft;
    if (!input || length==0 || input[0]<0 || input[0]>16384) return -1;
    const int count=static_cast<int>(input[0]);
    std::vector<Word> words;
    std::vector<int> text;
    std::size_t at=1, total=0;
    for (int i=0; i<count; ++i) {
        if (at>=length || input[at]<1 || input[at]>65536) return -1;
        const auto size=static_cast<std::size_t>(input[at++]);
        if (size>65536-total || size>length-at) return -1;
        words.push_back({static_cast<int>(text.size()),static_cast<int>(size)});
        for (std::size_t j=0; j<size; ++j) {
            if (input[at+j]<97 || input[at+j]>122) return -1;
            text.push_back(static_cast<int>(input[at+j]));
        }
        at+=size; total+=size; text.push_back(0);
    }
    if (at!=length) return -1;
    if (!output || capacity<total) return -2;
    if (count==0) return 0;
    const SuffixLcp lcp(text);
    std::vector<int> order(count);
    std::iota(order.begin(),order.end(),0);
    std::sort(order.begin(),order.end(),[&](int a,int b) {
        const Word left[2]={words[a],words[b]}, right[2]={words[b],words[a]};
        int li=0,ri=0,lp=0,rp=0;
        while (li<2 && ri<2) {
            const int limit=std::min(left[li].size-lp,right[ri].size-rp);
            const int common=lcp.common(left[li].start+lp,right[ri].start+rp,limit);
            if (common<limit) return text[left[li].start+lp+common]<text[right[ri].start+rp+common];
            lp+=common; rp+=common;
            if (lp==left[li].size) { ++li; lp=0; }
            if (rp==right[ri].size) { ++ri; rp=0; }
        }
        return a<b;
    });
    std::size_t written=0;
    for (int index:order) for (int j=0; j<words[index].size; ++j)
        output[written++]=static_cast<std::uint8_t>(text[words[index].start+j]);
    return static_cast<std::int64_t>(written);
}
