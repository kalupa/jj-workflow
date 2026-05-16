# Revsets: jj's revision selection language

A revset is an expression that resolves to a set of commits. Used anywhere a command takes a `-r` argument or similar. This is a functional DSL — not glob, not regex — with stable semantics.

For the full authoritative spec, run `jj help -k revsets`. This file covers the parts Claude will actually write.

## Symbol resolution order

When you write a bare name like `foo`, jj tries to resolve it in this order:

1. Tag name
2. Bookmark name
3. Git ref
4. Commit ID / change ID prefix

To force one interpretation, use `commit_id("abc")`, `change_id("abc")`, or quote the symbol. In scripts, prefer the explicit functions.

## Operators (by binding power, strongest first)

```
f(x)                  function call
x-     x+             parent(s) / child(ren) of x
p:x                   pattern (e.g. glob:"main*")
x::    ::x   x..  ..x descendants / ancestors / range
x::y   x..y           ranged variants — see below
~x                    complement
x & y                 intersection
x ~ y                 set difference
x | y                 union
```

### `x::y` vs `x..y` — the trap

These two range operators look similar but differ in a way that bites:

- **`x..y`** = ancestors of `y` that are *not* ancestors of `x`. Matches `git log x..y`. `x` and `y` need not be related.
- **`x::y`** = descendants of `x` that are *also* ancestors of `y` (the DAG path between them). Matches `git log --ancestry-path x..y`. Empty if there is no path.

Rule of thumb: use `..` for "what's new in y compared to x" (the common one). Use `::` when you specifically want the path.

### `..` does not distribute over `|`

`(A | B)..` ≠ `A.. | B..`. The former means "commits not ancestors of A *and* not ancestors of B" (in fact equals `A.. & B..`); the latter is the union. When in doubt, parenthesize explicitly.

## Frequently used functions

### DAG navigation
- `all()` — every visible commit
- `none()` — empty (useful with `coalesce`)
- `root()` — the virtual root commit (change ID `zzzzzzzz`)
- `visible_heads()` — heads of the visible graph
- `heads(x)` — commits in `x` with no descendants also in `x`
- `roots(x)` — commits in `x` with no ancestors also in `x`
- `connected(x)` — same as `x::x` (fill the gaps in a sparse set)
- `reachable(srcs, domain)` — commits reachable from `srcs` via parent/child edges, restricted to `domain`. Common idiom: `reachable(@, mutable())` for "the stack I'm working on".
- `fork_point(x)` — common ancestor where commits in `x` diverged
- `merges()` — merge commits
- `latest(x, [count])` — most recent `count` by committer date

### Bookmarks, tags, remotes
- `bookmarks([pattern])` — local bookmark targets
- `remote_bookmarks([name], [remote=pat])` — remote-tracking bookmark targets. Git-tracking bookmarks excluded unless `remote="git"` or `remote="*"`.
- `tracked_remote_bookmarks(...)` / `untracked_remote_bookmarks(...)`
- `tags([pattern])`, `remote_tags(...)`
- `trunk()` — the configured trunk (usually `main@origin` or similar). Always exactly one commit.

### Identity, authorship, content
- `mine()` — author email equals current user
- `author(pat)` / `author_name(pat)` / `author_email(pat)` / `author_date(pat)`
- `committer(pat)` / `committer_name(pat)` / `committer_email(pat)` / `committer_date(pat)`
- `description(pat)` — pattern matches full description. Use `description("")` for empty.
- `subject(pat)` — pattern matches first line only
- `signed()` — cryptographically signed
- `empty()` — modifies no files (includes empty merges, `root()`)
- `conflicts()` — has conflicted files
- `divergent()` — change ID has multiple visible commits
- `files(fileset-expr)` — modifies paths matching the [fileset](filesets.md)
- `diff_lines(text, [files])` — adds or removes lines matching `text`
- `diff_lines_added(text, [files])` / `diff_lines_removed(text, [files])`

### IDs and safety
- `commit_id("prefix")` / `change_id("prefix")` — force ID interpretation
- `present(x)` — `x`, or `none()` if `x` references something that doesn't exist. Use to make scripts tolerant of missing bookmarks.
- `coalesce(a, b, c, ...)` — first non-empty revset. Pairs well with `present()`.
- `exactly(x, n)` — error if `|x| ≠ n`. Defensive guard.

### Immutability set
- `immutable_heads()` — heads of the immutable region (default: `trunk() | tags() | untracked_remote_bookmarks()`)
- `immutable()` = `::immutable_heads() | root()`
- `mutable()` = `~immutable()`

Anything in `immutable()` cannot be rewritten without `--ignore-immutable`.

## String patterns (used inside `bookmarks()`, `description()`, etc.)

Default is `glob:`. Available kinds:

- `exact:"s"` — equal to
- `glob:"p"` — Unix shell glob
- `regex:"p"` — Rust regex syntax
- `substring:"s"` — contains

Append `-i` for case-insensitive: `glob-i:"FIX*"`. Patterns themselves compose with `&`, `|`, `~`: `bookmarks(~glob:"ci/*")`.

## Date patterns (used inside `author_date`, `committer_date`)

- `after:"2024-02-01"`, `before:"yesterday"`, `after:"5 minutes ago"`
- ISO 8601, partial dates, and natural language ("yesterday 5pm", "2 days ago") all accepted.

## Hidden commits

Most revsets only search **visible** commits. To reach abandoned/hidden commits, mention them explicitly by commit ID, by `<name>@<remote>`, or via `at_operation()`. Once mentioned, their ancestors enter the search space.

`at_operation(op, x)` evaluates `x` against the repo state at a past operation — useful for forensic queries: `at_operation(@-, visible_heads())`.

## Aliases

User and built-in aliases live in `[revset-aliases]` in config. Always check `jj config list revset-aliases` at session start — the user may have redefined `trunk()`, `immutable_heads()`, or added shorthand. Example built-ins:

```toml
[revset-aliases]
'HEAD' = '@-'
'user()' = 'user("me@example.org")'
'grep:x' = 'description(regex:x)'
```

A user-defined `grep:foo` makes `description(regex:foo)` available as a one-liner.

## Quoting

Symbols that contain operator characters need inner quotes:

```bash
jj log -r '"x-"'        # the bookmark literally named x-, not parents-of-x
```

Shell quoting (outer) is separate from revset quoting (inner). Single-quote the whole expression in the shell, double-quote symbols inside.

## Useful idioms

```bash
jj log -r '@'                              # working copy
jj log -r '@-'                             # parent of @
jj log -r '::@'                            # all ancestors of @
jj log -r 'trunk()..@'                     # my work not yet on trunk
jj log -r '(trunk()..@)::'                 # my stack + its descendants
jj log -r 'reachable(@, mutable())'        # the stack I can rewrite
jj log -r 'remote_bookmarks()..'           # commits not on any remote
jj log -r 'mine() & description(*WIP*)'    # my WIP commits
jj log -r 'author_date(after:"yesterday")' # recent work
jj log -r 'tags() | bookmarks()'           # decorated commits only
jj log -r 'empty() & mutable()'            # empty commits I can drop
jj log -r 'conflicts()'                    # anything currently broken
jj log -r 'files("src/foo.rs")'            # history touching one file
jj log -r 'diff_lines("TODO", "src")'      # commits that added/removed TODO under src
jj abandon -r 'empty() & mutable() ~ @'    # cleanup empty intermediates
```

## When the revset evaluates to nothing

`jj` commands that expect one commit error on empty or multi-commit revsets. If you need a script-safe fallback, use `coalesce(present(maybe), @)`. If you want to assert size, wrap with `exactly(x, 1)`.
