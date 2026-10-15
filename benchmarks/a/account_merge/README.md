# Account Merge

Merge account records that share at least one email address. A disjoint-set structure joins account indices through shared email strings; each component then emits one owner name and its sorted unique emails. The ports use path compression, union by rank, and an open-addressed table for email lookup.

## Contract

- Input is a signed 64-bit array encoded as `[account_count, name_length, name_bytes..., email_count, (email_length, email_bytes...)*]`. The account count is 0 through 64, names and emails are 1 through 64 bytes, and all text is printable ASCII; email bytes exclude spaces. The array must contain exactly the declared records and no more than 1,024 email references.
- Duplicate emails within one account are ignored. Accounts linked by shared emails must use the same name; inputs that violate this rule are invalid. Accounts without emails remain separate groups.
- Return the number of bytes written. The output is a u16 little-endian group count, followed by each group's u16 name length, u16 unique-email count, name bytes, and lexicographically sorted email records (u16 length followed by bytes). Groups sort by name, with no-email groups first, then by first email.
- Malformed input returns `-1`; insufficient output capacity returns `-2`. The input is read-only.

The workload covers the published example, transitive merges, duplicate addresses, same-name independent groups, email-free accounts, empty input, malformed components and encodings, and maximum account/email-reference bounds. The shared `i64_array_bytes_output` ABI is used for all nine languages.

The pinned Java [AccountMerge.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/AccountMerge.java) uses union-find to join accounts through shared emails, then sorts emails and merged rows. This is distinct from the generic disjoint-set trace benchmark: it adds email indexing, group aggregation, and deterministic sorted output.

Build with `python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm account_merge --language LANGUAGE` and record with `python3 benchmarks/run_i64_array_bytes_output.py --algorithm account_merge`.
