# Filesets: jj's file selection language

A fileset is an expression that resolves to a set of paths. Used as positional file arguments to `jj diff`, `jj file`, `jj split`, `jj squash`, `jj restore`, etc., and inside the `files()` revset function.

Filesets look like shell paths but are **not** shell globs. Bare `*.rs` does not work — that's a path literal, not a pattern.

For the full spec, run `jj help -k filesets`.

## Default interpretation

A bare `"path"` is parsed as `prefix-glob:"path"`: matches that path **and everything under it** if it's a directory. So `jj diff src` matches every file under `src/`.

## Pattern prefixes

Cwd-relative (the default basis):

| Prefix | Matches |
|--------|---------|
| `cwd:"path"` (default) | cwd-relative path prefix — file or dir-recursive |
| `file:"path"` / `cwd-file:"path"` | exact cwd-relative path, no recursion |
| `glob:"pat"` / `cwd-glob:"pat"` | shell wildcard, cwd-relative, **non-recursive** |
| `prefix-glob:"pat"` | `glob:` plus matches paths *under* a directory match |

Workspace-root-relative (ignore cwd):

| Prefix | Matches |
|--------|---------|
| `root:"path"` | workspace-relative prefix |
| `root-file:"path"` | exact workspace-relative path |
| `root-glob:"pat"` | workspace-relative glob |
| `root-prefix-glob:"pat"` | workspace-relative prefix-glob |

Case-insensitive: append `-i` to the prefix: `glob-i:"*.TXT"` matches both `file.txt` and `FILE.TXT`.

### The glob vs prefix-glob trap

- `glob:"*.d"` matches `foo.d` in cwd, but **not** files under a directory called `foo.d/`.
- `prefix-glob:"*.d"` matches both — equivalent to `glob:"*.d" | glob:"*.d/**"`.

If you want "all Rust files recursively from cwd", write `glob:"**/*.rs"` (the `**` is explicit), not `*.rs`.

## Operators

Same shape as revsets, lower-power-first:

```
f(x)         function call
p:x          pattern
~x           complement
x & y        intersection
x ~ y        difference
x | y        union (lowest priority)
```

## Functions

Only two are useful in practice:

- `all()` — every file
- `none()` — no files

## Quoting

Inner quotes around `"path"` are required when the path contains whitespace, glob meta characters, or any operator. They are optional otherwise. Shell quoting (single quotes around the whole arg) is almost always needed because `&`, `|`, `~`, `*`, and `?` are shell-meta too.

```bash
jj diff 'src ~ glob:"**/*.rs"'      # src minus Rust files
jj diff '~Cargo.lock'                # everything except Cargo.lock
jj diff '"Foo Bar"'                  # path with a space
jj diff '~"Foo Bar"'                 # complement of that path (inner quotes required)
```

## Aliases

Defined in `[fileset-aliases]`:

```toml
[fileset-aliases]
'LOCK' = '**/Cargo.lock | **/package-lock.json | **/uv.lock'
'not:x' = '~x'
```

`jj config list fileset-aliases` at session start surfaces these.

## Useful idioms

```bash
jj diff '~Cargo.lock'                      # diff excluding lockfile
jj file list 'src ~ glob:"**/*.rs"'        # non-Rust files in src
jj split '~foo'                            # split: foo stays in @, everything else moves
jj squash 'src/auth' -m "auth fixes"       # squash only auth subtree
jj restore --from <id> 'glob:"**/*.snap"'  # restore snapshot files from another commit
jj log -r 'files("src/foo.rs")'            # revset use: history touching one file
jj log -r 'files("glob:**/*.proto")'       # any proto edit
```

## When to use root: vs cwd:

Inside scripts or hooks running from arbitrary directories, prefer `root:` / `root-file:` / `root-glob:` so paths resolve identically regardless of where the script was launched. For interactive use, the cwd-relative default is what you want.
