# asuka4scape

iOS 27 jailbreak PoC — KASLR bypass + SPTM race condition

## Status

| Phase | Status | Description |
|-------|--------|-------------|
| 1. KASLR bypass | ✅ Working | Kernel slide leaked via user-space RW region scanning |
| 2. SPTM race | ✅ Working | PTE write on READ-only userspace pages via race condition |
| 3. Kernel read | ✅ Working | sysctl copyout during SPTM race window |
| 4. tfp0 | ❌ **STUCK** | IOSurface UAF patched, need alternative approach |
| 5. Find proc | ⏳ Ready | Scan `__DATA` by PID (requires tfp0) |
| 6. Root | ⏳ Ready | Set `cr_uid = 0` (requires tfp0) |
| 7. CS flags | ⏳ Ready | Clear restrictions, set platform (requires tfp0) |
| 8. Sandbox | ⏳ Ready | Null sandbox pointer (requires tfp0) |
| 9. Finalize | ⏳ Ready | Create `/var/jb/` marker |

## How KASLR Bypass Works

iOS uses KASLR to randomize the kernel base address at boot. The slide is
added to all static segment addresses.

The kernel frequently leaves pointers to itself in user-accessible memory.
asuka4scape scans all read-write VM regions for values in the kernel pointer range
(0xFFFFFFF000000000-0xFFFFFFF100000000). For each candidate, we subtract
each known static segment base. If the result is positive, page-aligned,
and less than 64MB, it is a valid slide candidate. asuka4scape groups by slide value
and pick the most frequent.

Result: slide 0xC674000 (varies per boot).

## How SPTM Race Works

SPTM (Secure Page Table Manager) is part of PPL. When sptm_stability_hacks=0
(default on production devices), SPTM uses a shared lock instead of an
exclusive lock in pmap_protect and pmap_enter.

Two threads on separate CPU cores race vm_protect on the same page. The
main thread calls vm_write on the READ-only page. During the ~15-20
instruction race window, the PTE may have WRITE while the VM region entry
says READ. vm_write and copyout check the PTE directly, not the VM region.

Success rate: ~12.5% per attempt.

What this gives us:
- Write to READ-only userspace pages
- Read kernel strings via sysctlbyname + copyout during race window

What this does NOT give us:
- Kernel read/write (PTE race only works on TTBR0/userspace)
- Access to PPL memory (page tables are in TTBR1/kernel space)

## Why asuka4scape Is Stuck at Phase 4

SPTM race gives us a powerful userspace primitive but no kernel R/W.
To complete the jailbreak, we need tfp0 (kernel task port) which requires
either:

1. A new IOKit bug — IOSurface UAF (kfd landa) is patched on iOS 27.
   Audit AGXDeviceUserClient, AppleBCMWLANUserClient, etc.
2. Double-copyin via SPTM race — Find a syscall that reads user data
   twice without re-validation. SPTM race modifies data between reads.
3. OOL ports race — Race mach_msg OOL_PORTS descriptor processing.
4. mach_zone_force_gc + heap spray — Force GC, free kernel object,
   spray with fake data.

## Target Devices

- iPhone 14 (iPhone14,7) — A15 Bionic — ONLY tested device
- 
- iOS 27.0 developer beta 6
- arm64e architecture with PAC, SPTM, PPL, KTRR

## Building

Requires Theos installed at ~/theos.

    cd asuka4scape
    ./build.sh

Output: SPTMRace.ipa

## Verified Offsets (from Ghidra)

    task->bsd_info     = 0x410
    proc->ucred        = 0x28
    proc->task         = 0x08
    proc->csflags      = 0x2B8
    proc->sandbox      = 0x3C0
    proc->p_pid        = 0x60
    ucred->cr_uid      = 0x18
    ip_kobject         = 0x50

## License

MIT
