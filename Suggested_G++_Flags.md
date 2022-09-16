# Part 1: Suggested flags to use in GCC/g++
[https://stackoverflow.com/questions/5088460/flags-to-enable-thorough-and-verbose-g-warnings](https://stackoverflow.com/questions/5088460/flags-to-enable-thorough-and-verbose-g-warnings)
### From : David Stone & (Edited by) HostileFork says dont trust SE
I went through and found the minimal set of includes that should get the maximum level of warning. I then removed from that list the set of warnings that I feel do not actually indicate something bad is happening, or else have too many false positives to be used in a real build. I commented as to why each of the ones I excluded were excluded. This is my final set of suggested warnings:

-pedantic -Wall -Wextra -Wcast-align -Wcast-qual -Wctor-dtor-privacy -Wdisabled-optimization -Wformat=2 -Winit-self -Wlogical-op -Wmissing-declarations -Wmissing-include-dirs -Wnoexcept -Wold-style-cast -Woverloaded-virtual -Wredundant-decls -Wshadow -Wsign-conversion -Wsign-promo -Wstrict-null-sentinel -Wstrict-overflow=5 -Wswitch-default -Wundef -Werror -Wno-unused

Questionable warnings that are present:

I include -Wno-unused because I often have variables that I know I will use later, but do not yet have the functionality written for. Removing warnings about that allows me to write in my preferred style of occasionally deferring the implementation of things. It is useful to turn that off every once in a while to make sure nothing slipped through the cracks.
-Wdisabled-optimization seems like a strong user-preference setting. I just added this one to my build (only for optimized builds for obvious reasons) and it didn't turn anything up, so it doesn't seem to be an especially chatty warning, at least for the way I code. I include it (even though code that triggers this warning isn't necessarily wrong) because I believe in working with my tools instead of against them. If gcc is telling me that it cannot optimize code for the way I wrote it, then I should look at rewriting it. I suspect that code that triggers this warning could benefit from being more modular, regardless, so although the code is not technically wrong (probably), stylistically it likely is.
-Wfloat-equal warns for safe equality comparisons (in particular, comparison with a non-computed value of -1). An example in my code where I use this is that I have a vector of float. I go through this vector, and there are some elements I cannot evaluate yet what they should be, so I set them to -1.0f (since my problem only uses positive numbers, -1 is out of the domain). I later go through and update -1.0f values. It does not easily lend itself to a different method of operation. I suspect that most people don't have this problem, and comparison of an exact number in floating point is probably an error, so I'm including it in the default list.
-Wold-style-cast has a lot of false positives in library code I'm using. In particular, the htonl family of functions used in networking, as well as a Rijndael (AES) encryption implementation I'm using has old-style casts that it warns me about. I intend to replace both of these, but I'm not sure if there is anything else in my code that it will complain about. Most users should probably have this on by default, though.
-Wsign-conversion was a tough one (and almost didn't make the list). Turning it on in my code generated a huge amount of warnings (100+). Almost all of them were innocent. However, I have been careful to use signed integers wherever I wasn't sure, although for my particular problem domain, I would usually get a slight efficiency increase using unsigned values due to the large amount of integer division I do. I sacrificed this efficiency because I was concerned about accidentally promoting a signed integer to an unsigned and then dividing (which is not safe, unlike addition, subtraction, and multiplication). Turning on this warning allowed me to safely change most of my variables to unsigned types and add a few casts in some other places. It's currently a little hard to use because the warning isn't that smart. For instance, if you do unsigned short + (integral
constant expression), that result is implicitly promoted to int. It then warns about a potential sign problem if you assign that value to unsigned or unsigned short, even though it's safe. This is definitely the most optional warning for almost all users.
-Wsign-promo: see -Wsign-conversion.
-Wswitch-default seems pointless (you don't always want a default case if you've enumerated all possibilities explicitly). However, turning on this warning can enforce something that is probably a good idea. For cases where you explicitly want to ignore everything except the listed possibilities (but other numbers are possible), then put in default: break; to make it explicit. If you explicitly enumerate all possibilities, then turning on this warning will help ensure that you put something like assert (false) to make sure that you've actually covered all possible options. It lets you be explicit in what the domain of your problem is and programatically enforces that. However, you'll have to be careful in just sticking assert (false) everywhere. It's better than doing nothing with the default case, but as usual with assert, it won't work in release builds. In other words, you cannot rely on it to validate numbers that you get from, say, a network connection or a database that you do not have absolute control over. Exceptions or returning early are the best way to handle that (but still require you to have a default case!).
-Werror is an important one for me. When compiling large amounts of code in a multi-threaded build with multiple targets, it's easy for a warning to slip by. Turning warnings into errors ensures that I notice them.
Then there is a set of warnings that are not included in the above list because I did not find them to be useful. These are the warnings and my comments on why I'm not including them in the default list:

Warnings that are absent:

-Wabi is not needed because I'm not combining binaries from different compilers. I tried compiling with it anyway, and it didn't trigger, so it doesn't seem needlessly verbose.
-Waggregate-return is not something that I consider an error. For instance, it triggers when using a range-based for loop on a vector of classes. Return value optimization should take care of any negative effects of this.
-Wconversion triggers on this code: short n = 0; n += 2; The implicit conversion to int causes a warning when it's then converted back to its target type.
-Weffc++ includes a warning if all data members are not initialized in the initializer list. I intentionally do not do this in many cases, so the set of warnings is too cluttered to be useful. It's helpful to turn on every once in a while and scan for other warnings, though (such as non-virtual destructors of base classes). This would be more useful as a collection of warnings (like -Wall) instead of a single warning on its own.
-Winline is absent because I don't use the inline keyword for optimization purposes, just to define functions inline in headers. I don't care if the optimizer actually inlines it. This warning also complains if it can't inline a function declared in a class body (such as an empty virtual destructor).
-Winvalid-pch is missing because I don't use precompiled headers.
-Wmissing-format-attribute is not used because I do not use gnu extensions. Same for -Wsuggest-attribute and several others
Potentially notable for its absence is -Wno-long-long, which I have no need for. I compile with -std=c++0x (-std=c++11 in GCC 4.7), which includes long long integer types. Those stuck back on C++98 / C++03 may consider adding that exclusion from the warning list.
-Wnormalized=nfc is already the default option, and looks to be the best.
-Wpadded is turned on occasionally to optimize the layout of classes, but it is not left on because not all classes have enough elements to remove padding at the end. In theory I could get some extra variables for 'free', but it's not worth the extra effort of maintaining that (if my class size changes, it's not easy to remove those previously free variables).
-Wstack-protector is not used because I do not use -fstack-protector
-Wstrict-aliasing=3 is turned on by -Wall and is the most accurate, but it looks like level 1 and 2 give more warnings. In theory a lower level is a 'stronger' warning, but it's at the cost of more false positives. My own test code compiled cleanly under all 3 levels.
-Wswitch-enum isn't behavior that I want. I don't want to handle every switch statement explicitly. It would be useful if the language had some mechanism to activate this on specified switch statements (to ensure that future changes to the enum are handled everywhere that they need to be), but it's overkill for an "all-or-nothing" setting.
-Wunsafe-loop-optimizations causes too many spurious warnings. It may be useful to apply this one periodically and manually verify the results. As an example, it generated this warning in my code when I looped over all elements in a vector to apply a set of functions to them (using the range-based for loop). It is also warning for the constructor of a const array of const std::string (where this is no loop in user code).
-Wzero-as-null-pointer-constant and -Wuseless-cast are GCC-4.7-only warnings, which I will add when I transition to GCC 4.7.
I've filed a few bug reports / enhancement requests at gcc as a result of some of this research, so hopefully I'll be able to eventually add more of the warnings from the "do not include" list to the "include" list. This list includes all warnings mentioned in this thread (plus I think a few extra). Many of the warnings not explicitly mentioned in this post are included as part of another warning I do mention. If anyone notices any warnings that are excluded from this post entirely, let me know.

# Part 2
[https://developers.redhat.com/blog/2018/03/21/compiler-and-linker-flags-gcc](https://developers.redhat.com/blog/2018/03/21/compiler-and-linker-flags-gcc)

-D_FORTIFY_SOURCE=2
-D_GLIBCXX_ASSERTIONS
-fasynchronous-unwind-tables
-fexceptions
-fpie -Wl,-pie
-fpic -shared
-fplugin=annobin
-fstack-clash-protection
-fstack-protector
-fstack-protector-all
-fstack-protector-strong
-grecord-gcc-switches
-mcet -fcf-protection
-O2
-pipe
-Wall
-Werror=format-security
-Werror=implicit-function-declaration
-Wl,-z,defs
-Wl,-z,now
-Wl,-z,relro
 

Flag	Purpose	Applicable Red Hat Enterprise Linux versions	Applicable Fedora versions
-D_FORTIFY_SOURCE=2	Run-time buffer overflow detection	All	All
-D_GLIBCXX_ASSERTIONS	Run-time bounds checking for C++ strings and containers	All (but ineffective without DTS 6 or later)	All
-fasynchronous-unwind-tables	Increased reliability of backtraces	All (for aarch64, i386, s390, s390x, x86_64)	All (for aarch64, i386, s390x, x86_64)
-fexceptions	Enable table-based thread cancellation	All	All
-fpie -Wl,-pie	Full ASLR for executables	7 and later (for executables)	All (for executables)
-fpic -shared	No text relocations for shared libraries	All (for shared libraries)	All (for shared libraries)
-fplugin=annobin	Generate data for hardening quality control	Future	Fedora 28 and later
-fstack-clash-protection	Increased reliability of stack overflow detection	Future (after 7.5)	27 and later (except armhfp)
-fstack-protector or -fstack-protector-all	Stack smashing protector	6 only	n/a
-fstack-protector-strong	Likewise	7 and later	All
-g	Generate debugging information	All	All
-grecord-gcc-switches	Store compiler flags in debugging information	All	All
-mcet -fcf-protection	Control flow integrity protection	Future	28 and later (x86 only)
-O2	Recommended optimizations	All	All
-pipe	Avoid temporary files, speeding up builds	All	All
-Wall	Recommended compiler warnings	All	All
-Werror=format-security	Reject potentially unsafe format string arguents	All	All
-Werror=implicit-function-declaration	Reject missing function prototypes	All (C only)	All (C only)
-Wl,-z,defs	Detect and reject underlinking	All	All
-Wl,-z,now	Disable lazy binding	7 and later	All
-Wl,-z,relro	Read-only segments after relocation	6 and later	All