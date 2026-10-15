module gale_shapley;

// Proposer-proposing Gale-Shapley stable matching for complete preferences.
fn long gale_shapley(long* values, usz length, char* output, usz output_capacity)
    @export("gale_shapley")
{
    if (values == null || length < 1 || length > 66) return -2;
    if (values[0] < 0 || values[0] > 5) return -2;
    usz count = (usz)values[0];
    if (length != 1 + 2 * count * count) return -2;
    long[5][5] ranks;
    bool[5] seen;
    for (usz proposer = 0; proposer < count; proposer++) {
        for (usz index = 0; index < count; index++) seen[index] = false;
        for (usz rank = 0; rank < count; rank++) {
            long accepter = values[1 + proposer * count + rank];
            if (accepter < 0 || (ulong)accepter >= (ulong)count || seen[(usz)accepter]) return -2;
            seen[(usz)accepter] = true;
        }
    }
    usz accepter_offset = 1 + count * count;
    for (usz accepter = 0; accepter < count; accepter++) {
        for (usz index = 0; index < count; index++) seen[index] = false;
        for (usz rank = 0; rank < count; rank++) {
            long proposer = values[accepter_offset + accepter * count + rank];
            if (proposer < 0 || (ulong)proposer >= (ulong)count || seen[(usz)proposer]) return -2;
            seen[(usz)proposer] = true;
            ranks[accepter][(usz)proposer] = (long)rank;
        }
    }
    if (output_capacity < count || (count != 0 && output == null)) return -2;

    long[5] matched_proposer;
    long[5] matched_accepter;
    usz[5] next_choice;
    for (usz index = 0; index < count; index++) {
        matched_proposer[index] = -1;
        matched_accepter[index] = -1;
        next_choice[index] = 0;
    }
    while (true) {
        usz proposer = 0;
        while (proposer < count && matched_accepter[proposer] != -1) proposer++;
        if (proposer == count) break;
        usz preference_index = 1 + proposer * count + next_choice[proposer];
        next_choice[proposer]++;
        usz accepter = (usz)values[preference_index];
        long current = matched_proposer[accepter];
        if (current == -1 || ranks[accepter][proposer] < ranks[accepter][(usz)current]) {
            if (current != -1) matched_accepter[(usz)current] = -1;
            matched_proposer[accepter] = (long)proposer;
            matched_accepter[proposer] = (long)accepter;
        }
    }
    for (usz proposer = 0; proposer < count; proposer++) output[proposer] = (char)matched_accepter[proposer];
    return (long)count;
}
