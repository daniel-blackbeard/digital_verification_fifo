/*
 * Solver bridge for Verilator constrained randomization on Windows.
 *
 * Usage: z3_bridge <solver command line>      e.g. z3_bridge C:/msys64/ucrt64/bin/z3.exe --in
 *
 * Built with the MSYS (Cygwin runtime) gcc. It sits between the simulation and a
 * native Windows solver:
 *   - the solver's answers are read with a blocking Win32 ReadFile. A Cygwin read()
 *     on a pipe written by a native program polls on a timer instead, which costs
 *     about 15 ms per answer;
 *   - CR is removed from the answers (the native solver ends lines with CR LF);
 *   - the answers are forwarded with a Cygwin write(), which wakes the reader at once.
 */
#include <windows.h>
#include <pthread.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

static HANDLE to_solver;

static void *pump_requests(void *arg) {
    char buf[4096];
    ssize_t n;
    (void)arg;
    while ((n = read(STDIN_FILENO, buf, sizeof buf)) > 0) {
        DWORD done = 0, w;
        while (done < (DWORD)n) {
            if (!WriteFile(to_solver, buf + done, (DWORD)n - done, &w, NULL)) return NULL;
            done += w;
        }
    }
    CloseHandle(to_solver); /* end of input: the solver exits */
    return NULL;
}

int main(int argc, char **argv) {
    SECURITY_ATTRIBUTES sa = { sizeof sa, NULL, TRUE };
    HANDLE in_rd, in_wr, out_rd, out_wr;
    STARTUPINFOA si;
    PROCESS_INFORMATION pi;
    char cmd[4096] = "";
    pthread_t th;
    int i;

    if (argc < 2) { fprintf(stderr, "usage: %s <solver command line>\n", argv[0]); return 2; }
    for (i = 1; i < argc; i++) {
        if (strlen(cmd) + strlen(argv[i]) + 2 > sizeof cmd) { fprintf(stderr, "z3_bridge: command too long\n"); return 2; }
        if (i > 1) strcat(cmd, " ");
        strcat(cmd, argv[i]);
    }

    if (!CreatePipe(&in_rd, &in_wr, &sa, 0) || !CreatePipe(&out_rd, &out_wr, &sa, 0)) {
        fprintf(stderr, "z3_bridge: CreatePipe failed (%u)\n", GetLastError());
        return 1;
    }
    /* Only the solver's ends are inherited. */
    SetHandleInformation(in_wr, HANDLE_FLAG_INHERIT, 0);
    SetHandleInformation(out_rd, HANDLE_FLAG_INHERIT, 0);

    memset(&si, 0, sizeof si);
    si.cb = sizeof si;
    si.dwFlags = STARTF_USESTDHANDLES;
    si.hStdInput = in_rd;
    si.hStdOutput = out_wr;
    si.hStdError = GetStdHandle(STD_ERROR_HANDLE);
    if (!CreateProcessA(NULL, cmd, NULL, NULL, TRUE, 0, NULL, NULL, &si, &pi)) {
        fprintf(stderr, "z3_bridge: cannot start '%s' (%u)\n", cmd, GetLastError());
        return 1;
    }
    CloseHandle(in_rd);
    CloseHandle(out_wr);
    to_solver = in_wr;

    pthread_create(&th, NULL, pump_requests, NULL);

    for (;;) {
        char buf[4096];
        DWORD n, k, j = 0;
        if (!ReadFile(out_rd, buf, sizeof buf, &n, NULL) || n == 0) break;
        for (k = 0; k < n; k++) if (buf[k] != '\r') buf[j++] = buf[k];
        for (k = 0; k < j; ) {
            ssize_t w = write(STDOUT_FILENO, buf + k, j - k);
            if (w <= 0) { TerminateProcess(pi.hProcess, 1); return 1; }
            k += (DWORD)w;
        }
    }
    WaitForSingleObject(pi.hProcess, 2000);
    return 0;
}
