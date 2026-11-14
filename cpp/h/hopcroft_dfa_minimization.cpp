// Independent Hopcroft partition-refinement draft; uncompiled and unrun.
#include <cstddef>
#include <cstdint>
#include <deque>
#include <utility>
#include <vector>

extern "C" std::int64_t hopcroft_dfa_minimization(const std::int64_t* input, std::size_t length) {
    if (!input || length < 2 || input[0] < 1 || input[0] > 4096 || input[1] < 1 || input[1] > 4) return -1;
    const int n=static_cast<int>(input[0]), k=static_cast<int>(input[1]);
    if (length != 2 + static_cast<std::size_t>(n) * (1 + k)) return -1;
    for (int s=0; s<n; ++s) if (input[2+s] != 0 && input[2+s] != 1) return -1;
    for (int i=0; i<n*k; ++i) if (input[2+n+i] < 0 || input[2+n+i] >= n) return -1;
    // Head/next adjacency keeps all predecessor edges in O(k*n) storage.
    std::vector<int> head(k*n,-1), next(k*n,-1);
    for (int s=0; s<n; ++s) for (int c=0; c<k; ++c) {
        const int edge=s*k+c, dest=static_cast<int>(input[2+n+edge]);
        next[edge]=head[c*n+dest]; head[c*n+dest]=edge;
    }
    std::vector<std::vector<int>> blocks(2);
    std::vector<int> block_of(n), position(n);
    for (int s=0; s<n; ++s) {
        int block=static_cast<int>(input[2+s]);
        block_of[s]=block; position[s]=static_cast<int>(blocks[block].size()); blocks[block].push_back(s);
    }
    if (blocks[0].empty()) { blocks[0]=std::move(blocks[1]); blocks.pop_back(); }
    else if (blocks[1].empty()) blocks.pop_back();
    for (std::size_t b=0; b<blocks.size(); ++b)
        for (std::size_t i=0; i<blocks[b].size(); ++i) { block_of[blocks[b][i]]=static_cast<int>(b); position[blocks[b][i]]=static_cast<int>(i); }
    std::deque<std::pair<int,int>> work;
    std::vector<unsigned char> queued(static_cast<std::size_t>(n)*k,0);
    auto enqueue=[&](int block,int symbol) {
        const int id=block*k+symbol;
        if (!queued[id]) { queued[id]=1; work.emplace_back(block,symbol); }
    };
    for (std::size_t b=0; b<blocks.size(); ++b) for (int c=0; c<k; ++c) enqueue(static_cast<int>(b),c);
    std::vector<int> marked(n,0), touched;
    std::vector<std::vector<int>> selected(n);
    int epoch=0;
    while (!work.empty()) {
        auto [splitter,symbol]=work.front(); work.pop_front(); queued[splitter*k+symbol]=0;
        ++epoch; touched.clear();
        for (int dest:blocks[splitter]) for (int e=head[symbol*n+dest]; e!=-1; e=next[e]) {
            int state=e/k;
            if (marked[state]==epoch) continue;
            marked[state]=epoch;
            int b=block_of[state];
            if (selected[b].empty()) touched.push_back(b);
            selected[b].push_back(state);
        }
        for (int b:touched) {
            if (selected[b].size() == blocks[b].size()) { std::vector<int>().swap(selected[b]); continue; }
            const int new_block=static_cast<int>(blocks.size());
            blocks.emplace_back();
            // Move only marked states, using swap-removal within their old blocks.
            for (int state:selected[b]) {
                int pos=position[state], last=blocks[b].back();
                blocks[b][pos]=last; position[last]=pos; blocks[b].pop_back();
                position[state]=static_cast<int>(blocks[new_block].size());
                blocks[new_block].push_back(state); block_of[state]=new_block;
            }
            // Reclaim a block's spare capacity only after geometric shrinkage;
            // this bounds retained storage while amortizing the copying.
            if (blocks[b].size() * 2 < blocks[b].capacity())
                std::vector<int>(blocks[b]).swap(blocks[b]);
            std::vector<int>().swap(selected[b]);
            for (int c=0; c<k; ++c) {
                if (queued[b*k+c]) enqueue(new_block,c);
                else enqueue(blocks[new_block].size()<blocks[b].size() ? new_block : b,c);
            }
        }
    }
    return static_cast<std::int64_t>(blocks.size());
}
