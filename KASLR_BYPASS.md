# KASLR Bypass — How It Works

## What is KASLR

KASLR (Kernel Address Space Layout Randomization) randomizes the kernel base
address at boot. The slide is added to all static segment addresses. Without
knowing the slide, asuka4scape cannot calculate runtime kernel addresses.

On iOS 27, the KASLR slide is aligned to 0x200000 (2MB) and falls within the
range 0x0 - 0x4000000 (64MB).

## The Leak

The kernel frequently leaves pointers to itself in user-accessible memory.
Shared memory regions, mach port structures, and VM region metadata all
contain kernel pointers that are visible from user space.

asuka4scape scans all read-write VM regions of the current process for values
in the kernel pointer range (0xFFFFFFF000000000 - 0xFFFFFFF100000000).

## Algorithm

1. Enumerate all VM regions via mach_vm_region
2. Filter for RW regions (info.protection & VM_PROT_WRITE)
3. For each region: scan every 8 bytes (qword aligned)
4. Validate: is the value in the kernel pointer range?
5. For each valid pointer: subtract each known static segment base
6. If the result is positive, aligned to 0x200000, and less than 64MB:
   it is a valid slide candidate
7. Group candidates by slide value
8. Select the slide with the highest confirmation count

## Static Segment Bases (pre-slide)

    __TEXT:           0xFFFFFFF007004000
    __DATA_CONST:     0xFFFFFFF007B80000
    __DATA_SPTM:      0xFFFFFFF0080C4000
    __TEXT_EXEC:      0xFFFFFFF008110000
    __TEXT_BOOT_EXEC: 0xFFFFFFF00A98C000
    __DATA:           0xFFFFFFF00ABD8000
    __LINKEDIT:       0xFFFFFFF00AE98000

## Pointer Validation

Not all values in the kernel pointer range are actual kernel pointers.
Garbage values like 0xFFFFFFFFFFFFFFFF (-1) or 0xFFFFFFFF00000000 are filtered
out by is_valid_kptr():

    static BOOL is_valid_kptr(uint64_t ptr) {
        if (ptr == 0) return NO;
        if (ptr == 0xFFFFFFFFFFFFFFFFULL) return NO;
        if (ptr == 0xFFFFFFFF00000000ULL) return NO;
        if (ptr >= 0xFFFFFFF000000000ULL && ptr < 0xFFFFFFF100000000ULL)
            return YES;
        if (ptr >= 0xFFFFFFE000000000ULL && ptr < 0xFFFFFFF000000000ULL)
            return YES;
        return NO;
    }

## Result

On the test device, the slide was confirmed as 0xC674000 with multiple
confirmations across different RW regions.

    Kernel __TEXT runtime  = 0xFFFFFFF013678000
    Kernel __DATA runtime  = 0xFFFFFFF01724C000

## Where This Code Lives

- asuka4scape.h — constants KTEXT_BASE, KDATA_CONST_BASE, etc.
- ASUKAExploit.mm — phaseKASLR method
- is_valid_kptr — pointer validation function

## Tested Device

iPhone 14 (iPhone14,7) — A15 Bionic
iOS 27.0 developer beta 6
arm64e architecture with PAC, SPTM, PPL, KTRR

