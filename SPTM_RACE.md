# SPTM Race Condition — How It Works

## What is SPTM

SPTM (Secure Page Table Manager) is part of PPL (Page Protection Layer). PPL
operates at a higher privilege level than the kernel. Only PPL can modify
page tables.

SPTM manages:
- PTE (Page Table Entries) for TTBR0 (user space)
- PTE for TTBR1 (kernel space)
- PTE for PPL memory

## The Bug

When sptm_stability_hacks=0 (DEFAULT on production devices):
- SPTM uses a SHARED (read) lock in pmap_protect and pmap_enter
- Instead of an EXCLUSIVE (write) lock
- Lock mode verification is SKIPPED

This creates a race condition.

## The Flag

The sptm_stability_hacks flag is stored in __DATA_CONST at a fixed address:
- Pre-slide:  0xFFFFFFF0079E27E1
- Runtime:    0xFFFFFFF0079E27E1 + slide

The boot argument parser returns 0 when the argument is not found:
- kern.bootargs = "" (empty on production devices)
- Parser does not find sptm_stability_hacks
- Returns 0
- The return value is IGNORED in arm_init_sptm
- Default = 0 = shared lock = RACE CONDITION

## Check Sites

38 check sites for sptm_stability_hacks exist across 12+ pmap functions.

Assembly at each check site:

    ldrb w8, [x28, #0x7e1]     ; load flag
    tbz w8, #0x0, LAB_skip     ; if 0 = OFF = skip exclusive lock
    add x0, x19, #0x30         ; if 1 = ON = exclusive lock
    bl lck_rw_lock_exclusive   ; acquire exclusive lock

When flag=0: tbz jumps to LAB_skip, exclusive lock is NOT taken,
shared lock is used instead.

## The Race Window

Race window: between sptm_get_paddr_type (SPTM selector 0x0b) and
pmap_enter PTE modification (SPTM selector 0x02).

The window is approximately 15-20 instructions wide.

## Race Setup

Two threads on separate CPU cores race vm_protect on the same page:

- Thread A (core 0): vm_protect(page, VM_PROT_READ) — sets READ-only
- Thread B (core 1): vm_protect(page, VM_PROT_READ | VM_PROT_WRITE) — sets RW

Main thread: if vm_region says READ, calls vm_write.

During the race window:
- PTE may have WRITE even though VM region entry says READ
- vm_write checks PTE, not VM region entry
- vm_write succeeds on READ-only page
- copyout checks PTE, not VM region entry
- copyout succeeds on READ-only page

## CPU Affinity

If both threads are on the same core, they execute alternately (time-sliced).
Race window = 0 (threads never execute simultaneously).

Pin to different cores for true concurrent execution:

    Thread A: core 0 (performance, Everest)
    Thread B: core 1 (performance, Everest)

Using THREAD_AFFINITY_POLICY with affinity_tag = core + 1.

## Watchdog

iOS watchdog kills processes that load CPU too long.
Solution: usleep(10-200) in SPTM threads.

    #define RACE_THREAD_USLEEP    10
    #define WATCHDOG_USLEEP       100

## Success Rate

Approximately 1 in 8 attempts (12.5%).
On the test device: 335-499 out of 1000 vm_write successes.

## What This Gives Us

1. PTE WRITE primitive on userspace READ-only pages:
   - vm_write checks PTE, not VM region entry
   - During race window, PTE has WRITE
   - vm_write succeeds on READ-only page

2. Kernel string read via sysctl copyout:
   - sysctlbyname("kern.osversion", page_addr, &sz, NULL, 0)
   - Kernel reads from its own memory, calls copyout to READ-only page
   - copyout checks PTE, succeeds during race window
   - Kernel string appears on READ-only page

## What This Does NOT Give Us

1. vm_write to kernel addresses — FAIL
   - vm_write checks VM region entry BEFORE checking PTE
   - Kernel addresses are not in our VM map
   - vm_write returns KERN_FAILURE before PTE check

2. mach_vm_read to kernel addresses — CRASH
   - Kernel sees attempt to read kernel memory
   - Kills process (SIGKILL)

3. Access to PPL memory (page tables)
   - PPL memory is in TTBR1 (kernel space)
   - SPTM race only works on TTBR0 (userspace)

## SPTM Trampolines

Each SPTM call begins with a trampoline:

    BTI C           ; Branch Target Identifier
    MOVK X16, #sel  ; Load selector into x16
    B entry         ; Branch to SPTM entry

SPTM entry dispatches by x16:

    0xFFFFFFF00A39910C: PACIBSP     ; Sign return address
                        ; ... setup ...
                        ; switch on x16
                        ; call handler for selector

Known selectors:
- 0x02 = pmap_enter
- 0x0b = sptm_get_paddr_type
- Remaining ~25 selectors undocumented

## Where This Code Lives

- asuka4scape.h — SPTM_ENTRY_POINT, SPTM_STABILITY_FLAG, sptm_ctx_t
- ASUKAExploit.mm — sptm_read_thread, sptm_write_thread
- ASUKAExploit.mm — startSPTM, stopSPTM, phaseSPTMSanityCheck
- ASUKAExploit.mm — allocReadonlyPage, phaseKernelReadTest

## Tested Device

iPhone 14 (iPhone14,7) — A15 Bionic
iOS 27.0 developer beta 6
arm64e architecture with PAC, SPTM, PPL, KTRR

