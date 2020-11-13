#ifndef LUPAFROMLUA_H
#define LUPAFROMLUA_H

#if defined(_MSC_VER)
    /* Microsoft */
    #define DLL_EXPORT __declspec(dllexport)
    #define DLL_IMPORT __declspec(dllimport)
#elif defined(__GNUC__)
    /* GCC */
    #define DLL_EXPORT __attribute__((visibility("default")))
    #define DLL_IMPORT
#else
    /* do nothing and hope for the best? */
    #define DLL_EXPORT
    #define DLL_IMPORT
    #error "Unknown dynamic link import/export semantics."
#endif

#endif
