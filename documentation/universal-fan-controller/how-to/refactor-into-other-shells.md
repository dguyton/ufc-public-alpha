# UFC Feature Compatibility Across Shells
Bourne again SHell (BaSH) version 4.3+ is the base case. The Universal Fan Controller (UFC) was originally written in BaSH.

## Refactoring Level-of-Effort
When considering porting UFC from Bash to another SHell language variant, it's advisable to take into consideration the level-of-effort. Bash is a relatively sophisticated and complex version of SHell (I realize "complex" and "shell" in the same sentence sounds like an oxymoron, but bear with me here...). By default, Bash is not POSIX compliant. Although this author has endeavoured to make UFC's code *mostly* POSIX compliant Bash code, numerous lines of code in it are not. Quite frankly, with regards to some program functions I made the decision to go with convenience vs. compatibility. Besides, Bash is in common use and widely available.

That being said, I also understand that we each have our own preferred SHell iterations.

The chart below provides a high-level perspective of the level-of-effort that would be required to port UFC to another shell variant. Only the most common shells are shown.

### Refactoring Level-of-Effort by SHell Language

🔴 High = Major Bash features missing or incompatible; expect large-scale rewrites.</br>
🟡 Medium = Some common Bash features missing or different; refactor with care.</br>
🟢 Low = Mostly Bash-compatible; small adjustments may be needed.</br>


| Target Shell     | Refactoring Effort | Notes                                                                 |
|------------------|--------------------|-----------------------------------------------------------------------|
| `ash`            | 🔴 High            | Similar to `dash`; very limited Bash feature support. Used in BusyBox and Alpine. No array support. |
| `dash`           | 🔴 High            | POSIX only. No arrays, no `(( ))`, no `[[ ]]`, no `source`, no `declare`, etc. |
| `fish`           | 🔴 High            | Completely different syntax and paradigms; requires full rewrite. |
| `ksh93`          | 🟢 Low             | Good Bash compatibility, includes arrays, arithmetic, uses `typeset` (vs. `declare`). |
| `mksh`           | 🟡 Medium          | Indexed arrays, `(( ))`, some string ops; no associative arrays. |
| `yash`           | 🟡 Medium          | Strong POSIX compliance. Lacks associative arrays and Bashisms. |
| `zsh`            | 🟡 Medium          | Very capable but has syntax differences (e.g., 1-based arrays). |

---

### Detailed Refactoring Expectations
This table provides more detail from a functional perspective, so that you have a better idea of what to expect would be needed to port UFC to the alternative shell of your choice.

| Feature / Construct                 | POSIX? | `ash` | `dash` | `fish` | `ksh93` | `mksh` | `yash` | `zsh`   |
|-------------------------------------|--------|-------|--------|--------|--------|--------|---------|---------|
| `[ ... ]` test syntax               | ✅     | ✅   | ✅     | ❌   | ✅   | ✅     | ✅     | ✅      |
| `[ -eq / -lt / ... ]` math ops      | ✅     | ✅   | ✅     | ❌   | ✅   | ✅     | ✅     | ✅      |
| String tests with `=` / `!=`        | ✅     | ✅   | ✅     | ❌   | ✅   | ✅     | ✅     | ✅      |
| `(( ... ))` arithmetic expressions  | ❌     | ❌   | ❌     | ❌   | ✅   | ✅     | ✅     | ✅      |
| Arrays (indexed)                    | ❌     | ❌<sup>1</sup> | ❌ | ✅   | ✅<sup>2</sup>    | ✅<sup>3,4</sup>      | ✅<sup>4</sup>     | ✅<sup>5</sup>     |
| Associative arrays                  | ❌     | ❌<sup>1</sup> | ❌ | ✅   | ✅    | ❌     | ❌     | ✅      |
| `declare` / `typeset` / `local`     | ❌     | ❌   | ❌     | ❌   | ✅<sup>6</sup>   | ⚠️     | ✅     | ⚠️      |
| `${!var}` (indirect refs)           | ❌     | ❌   | ❌     | ❌   | ✅   | ❌     | ❌     | ❌      |
| Here strings (`<<<`)                | ❌     | ❌   | ❌     | ❌   | ✅   | ✅     | ✅     | ✅      |
| String substitution `${var//x/y}`   | ❌     | ❌   | ❌     | ❌   | ✅   | ✅     | ✅     | ✅      |
| `source` command                    | ❌     | ❌<sup>7</sup> | ❌ | ❌ |✅   |  ✅<sup>8</sup>   | ❌<sup>7</sup>  | ✅     | ✅      |

- **✅** = Fully supported in the shell.
- **❌** = Not supported — requires refactoring.
- **⚠️** = Supported but with partial compatibility or shell-specific behavior.

<sup>1</sup> `ash` has no support for arrays at all</br>
<sup>2</sup> `ksh93` uses `typeset -A` for associative arrays</br>
<sup>3</sup> `mksh` has minimal indexed array support, and associative arrays are not supported</br>
<sup>4</sup> `mksh` and `Yash` support indexed arrays only</br>
<sup>5</sup> `Zsh` indexed arrays begin with index 1 (Bash begins with index 0)</br>
<sup>6</sup> `ksh93` supports the `typeset` command only.</br>
<sup>7</sup> `ash` is strictly POSIX compliant only; `. {filename}` syntax is supported in `dash`/`ash`; `source {filename}` is not</br>
<sup>8</sup> `mksh`: supports `source` as a synonym for `.`</br>

#### Notes

1. `Zsh` arrays are **1-indexed** by default. Bash-style indexing must be explicitly enabled with `setopt KSH_ARRAYS`.
2. `${!var}` has **no direct equivalent in Zsh** or other POSIX shells — requires `eval`, `namerefs` (`typeset -n`), or redesign.
3. `fish` uses a unique syntax and is incompatible with POSIX or Bash.

---

## Notable Challenges in Code Migration

- indexed arrays start with 0
- might consider changing them to associative arrays if shell supports it, in order to keep this logic consistent
- relates to critical factors, such as zoned motherboards that expect there to be a "zone 0"

---

## Operating System Constraints
UFC was developed on Ubuntu server. When considering refactoring to other operating systems, the process can get more complex. As an example, consider the process of refactoring to FreeBSD.

Below, three examples are discussed: FreeBSD (built-in shell `bin/sh`), Python, and Perl.

### Refactoring Effort (from Bash 4.3+)

| Target Language     | Refactoring Effort | Notes                                                                 |
|---------------------|--------------------|-----------------------------------------------------------------------|
| `FreeBSD /bin/sh`   | 🔴 High            | Strictly POSIX; no Bashisms or arrays; minimal built-ins.            |
| `Python`            | 🔴 High            | Different language paradigm (structured, typed); full rewrite needed.|
| `Perl`              | 🔴 High            | Very different syntax; powerful, but requires complete redesign.     |

---

### Bash Feature Compatibility (FreeBSD sh / Python / Perl)

| Feature                      | FreeBSD sh | Python | Perl |
|-----------------------------|------------|--------|------|
| `[[ ... ]]`                 | ❌         | ❌     | ❌   |
| `(( ... ))`                 | ❌         | ❌<sup>1</sup>    | ✅<sup>2</sup>  |
| Indexed arrays              | ❌         | ✅     | ✅   |
| Associative arrays          | ❌         | ✅     | ✅   |
| `${!var}` (indirect ref)    | ❌         | ⚠️<sup>3</sup>    | ✅<sup>4</sup>  |
| `source` / `. file`         | ✅<sup>5</sup>        | ⚠️<sup>6</sup>    | ⚠️<sup>7</sup>  |
| `declare`, `typeset`, etc.  | ❌         | ❌     | ⚠️<sup>8</sup>  |
| String substitution         | ❌         | ✅     | ✅   |


✅ = Fully supported or natively available</br>
⚠️ = Possible with workarounds, different syntax, or non-native behavior</br>
❌ = Not supported; requires refactoring</br>

<sup>1</sup> Python supports arithmetic using +, -, etc., but not shell-style (( )).</br>
<sup>2</sup> Perl has robust arithmetic and supports ++, --, etc.</br>
<sup>3</sup> Python can emulate indirect references with dicts, globals(), or eval().</br>
<sup>4</sup> Perl supports symbolic references in certain contexts and full hash (associative array) support.</br>
<sup>5</sup> FreeBSD sh supports . file (POSIX-compatible), not source.</br>
<sup>6</sup> Python uses import, exec, or open(...).read() to source logic.</br>
<sup>7</sup> Perl uses require or do for external script sourcing.</br>
<sup>8</sup> Perl has my, our, and local, but no direct declare.</br>

---

### FreeBSD
Refactoring Bash scripts to FreeBSD’s introduces a few special considerations.

1. FreeBSD's default shell environment is `sh`, a POSIX-compliant shell based on Almquist (similar to `dash`).
2. Bash may be installed via ports or packages.

So, it's potentially a simple solution (just install a BaSH package). Just be certain a sufficient version of Bash will be installed (must be v4.3 or later).

---

## Refactoring UFC in Other Programming Languages
Refactoring UFC to another language is not really refactoring, but rather reconstituting its concepts onto another language model. This is totally do-able if one is willing to put in the effort, which would be substantial.

That said, the "hard part" so-to-speak has already been done for you. Quite frankly, the most difficult part of creating UFC in the first place was finding all of the manufacturer - and in some cases model - specific information that is required for the program to be useful.

### Python
Python is great for logic-heavy scripts and data processing. UFC's needs are relatively light-weight in terms of its context, which is one reason why the author decided SHell made more sense. Python is frankly overkill. However, it is certainly an option.

Refactoring a Bash script to Python means:
- Completely changing the paradigm (procedural shell scripting → structured programming)
- Explicit file handling, subprocess calls (subprocess.run, etc.)
- Manual recreation of environment variables, parameter parsing
- Arrays and dictionaries are well-supported, but no native shell expansion
- Control structures (if, for, while) are clearer but require indents and block scopes

### Perl
Perl is well-suited to legacy system administration automation. This makes it a candidate for operating a UFC-like application, but would require substantial work and essentially re-building UFC from the ground up, though the logic built-in to UFC could be replicated.

- Perl supports many shell tasks (file I/O, regex, arrays), but its syntax is very different
- Variables need sigils ($, @, %) and scoping (e.g., my, our)
- Modules for system interaction exist (IPC::Run, File::Path, etc.)
- Easier to emulate shell-style scripting than Python
- Perl usage is less common today, though experienced sysadmins may prefer it over Python

---

### Important Considerations
While the idea of utilizing a programming language that is more sophisticated than SHell may be tempting, consider some of the use cases around UFC which caused the author to lean in the direction of SHell to begin with, and how these might present additional challenges for other languages.

1. May need to re-think systemd daemon service usage.
2. SHell languages are immediately available. Other languages may present bottlenecks and additional challenges with ensuring they are pre-loaded before the systemd scripts attempt to run.
3. Need to ensure the operating environment is initialized fully before attempting to start the scripts in non-SHell languages. Small SHell scripts may still be required in order to verify the system environment before launching UFC.
4. Potential start-up delays could cause fan control to be delayed more than how quickly a native shell program can take over manual fan control
