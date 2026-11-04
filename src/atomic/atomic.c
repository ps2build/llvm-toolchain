#include <stdbool.h>
#include <stdint.h>

/* R5900 has no ll/sc. These are plain read-modify-write and are not interrupt-safe. */
#define ATOMIC_OPS(N, T)                                                                      \
    T __atomic_load_##N(const volatile void *p, int m) { return *(const volatile T *)p; }    \
    void __atomic_store_##N(volatile void *p, T v, int m) { *(volatile T *)p = v; }           \
    T __atomic_exchange_##N(volatile void *p, T v, int m) {                                   \
        T old = *(volatile T *)p;                                                             \
        *(volatile T *)p = v;                                                                 \
        return old;                                                                           \
    }                                                                                         \
    bool __atomic_compare_exchange_##N(volatile void *p, void *expected, T desired,           \
                                       bool weak, int ok, int fail) {                         \
        T *exp = (T *)expected;                                                               \
        T cur = *(volatile T *)p;                                                             \
        if (cur == *exp) {                                                                    \
            *(volatile T *)p = desired;                                                       \
            return true;                                                                      \
        }                                                                                     \
        *exp = cur;                                                                           \
        return false;                                                                         \
    }                                                                                         \
    T __atomic_fetch_add_##N(volatile void *p, T v, int m) {                                  \
        T old = *(volatile T *)p;                                                             \
        *(volatile T *)p = old + v;                                                           \
        return old;                                                                           \
    }                                                                                         \
    T __atomic_fetch_sub_##N(volatile void *p, T v, int m) {                                  \
        T old = *(volatile T *)p;                                                             \
        *(volatile T *)p = old - v;                                                           \
        return old;                                                                           \
    }                                                                                         \
    T __atomic_fetch_and_##N(volatile void *p, T v, int m) {                                  \
        T old = *(volatile T *)p;                                                             \
        *(volatile T *)p = old & v;                                                           \
        return old;                                                                           \
    }                                                                                         \
    T __atomic_fetch_or_##N(volatile void *p, T v, int m) {                                   \
        T old = *(volatile T *)p;                                                             \
        *(volatile T *)p = old | v;                                                           \
        return old;                                                                           \
    }                                                                                         \
    T __atomic_fetch_xor_##N(volatile void *p, T v, int m) {                                  \
        T old = *(volatile T *)p;                                                             \
        *(volatile T *)p = old ^ v;                                                           \
        return old;                                                                           \
    }

ATOMIC_OPS(1, uint8_t)
ATOMIC_OPS(2, uint16_t)
ATOMIC_OPS(4, uint32_t)
ATOMIC_OPS(8, uint64_t)
