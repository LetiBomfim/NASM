; ============================================================================
; args32.asm
; ----------------------------------------------------------------------------
; Tarefa: Montador NASM #6 - Passagem de parâmetros via linha de comando
;         em NASM a partir de um programa C
;
;   Este módulo recebe, de um programa C, o "argc" e o "argv" exatamente como
;   chegam à função main() do C. Ele percorre o vetor argv e lista cada
;   argumento recebido, usando a função da libc printf.
; ============================================================================

BITS 32

section .data
    fmt_argc        db "Total de argumentos (argc): %d", 10, 0
    fmt_arg         db '  argv[%d] = "%s"', 10, 0

section .text
    global process_args
    extern printf

process_args:
    push    ebp                  ; salva EBP do chamador
    mov     ebp, esp             ; novo frame de pilha: EBP aponta para o topo

    push    ebx                  ; preserva EBX do chamador
    push    esi                  ; preserva ESI do chamador
    push    edi                  ; preserva EDI do chamador

    mov     ebx, [ebp + 8]       ; EBX = argc
    mov     esi, [ebp + 12]      ; ESI = argv

    push    ebx                  ; empilha argc (2º argumento do printf)
    push    dword fmt_argc       ; empilha o formato (1º argumento do printf)
    call    printf  
    add     esp, 8               ; desfaz os 2 dwords empilhados (2 x 4 bytes)

    mov     edi, 0               ; EDI = i = 0

loop_argv:  
    cmp     edi, ebx             ; compara i com argc
    jge     fim                  ; se i >= argc, encerra o laço
  
    mov     edx, [esi + edi*4]   ; EDX = argv[i] (endereço da string i)

    push    edx                  ; empilha argv[i] (3º arg do printf)
    push    edi                  ; empilha i (2º arg do printf)
    push    dword fmt_arg        ; empilha o formato (1º arg do printf)
    call    printf  
    add     esp, 12              ; desfaz os 3 dwords empilhados (3 x 4 bytes)
  
    add     edi, 1               ; i++
    jmp     loop_argv  

fim:  
    pop     edi                  ; restaura EDI do chamador
    pop     esi                  ; restaura ESI do chamador
    pop     ebx                  ; restaura EBX do chamador
    pop     ebp                  ; restaura EBP do chamador (frame do chamador)
    ret                          ; retorna para quem chamou (main em C)
