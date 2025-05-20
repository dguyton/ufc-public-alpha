# POSIX Support
UFC is coded completely in the SHell (.sh) language ([BaSH](https://datahacker.blog/linux/bash/bash-bourne-again-shell) to be specific).

This conscious choice was made because SHell is a ubiquitous programming language, though of course there are variants, of which BaSH is one. In a further effort to support as many operating systems as possible across the Linux universe, UFC's programming _mostly_ follows the [POSIX standard](https://pubs.opengroup.org/onlinepubs/9699919799). This is not universally the case because there were some circumstances where a non-POSIX method of coding one section or another was - quite frankly - easier. However, an effort has been made to keep it _mostly_ POSIX compliant for the moment in an attempt to ease the burden on other programmers, should any wish to consider porting UFC to another variant of SHell. There are also plans to make it fully POSIX compliant, as noted in the [UFC future product roadmap](/documentation/universal-fan-controller/roadmap.md#make-posix-great-again).

Naturally, numerous other SHell variants are not POSIX compliant out-of-the-box either, but sticking to a common factor (POSIX) as much as possible will - it is hoped by this author - make porting the programs faster and easier, should anyone wish to do so.

> [!NOTE]
> Many UFC functions (subroutines) were written without bias toward POSIX compliance and are more likely to require tweaking to work correctly with other SHells (and definitely so for use in a true POSIX code environment).

## WTF is POSIX?
POSIX stands for **Portable Operating System Interface**. It is a set of standards defined by the IEEE (). It's goal is to improve code portability, i.e. ensuring compatibility between operating systems.

POSIX isn't an operating system in and of itself. And technically, it's not a SHell language either. POSIX is a _standard_ that governs how software interacts with any operating system, though with a heavy slant towards UNIX. It's basically a set of instructions on how to do certain things or how to handle certain situations in SHell coding. The idea is that no matter who you hand your code to, nor what operating system they are on, so long as it supports SHell, the program you share will work as intended.

Note that the slant toward UNIX mentioned above is one of the issues its biggest critics have with it. For example, POSIX is widely discussed in Linux forums, yet Linux is not UNIX. Nor is Windows, or Mac OS, etc. And yet although POSIX is ostensibly meant to be "universal," whether or not that is actually true is open for debate.

Regardless of the politics behind it, atm POSIX is the closest thing to a common standard for SHell programming. If one wishes to ensure uniformity of a SHell program across different operating systems and different SHell compilers, then aiming for POSIX compliance is currently your best option.

The downside to this approach is that most SHell compilers do not support POSIX natively, and many that do support it often don't support it completely or may be supporting an older iteration of the POSIX ruleset. Regardless, it's still the best approach for now if one is looking to code for ubiquity.
