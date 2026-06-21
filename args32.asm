; ============================================================================
; args32.asm
; ----------------------------------------------------------------------------
; Tarefa: Montador NASM #6 - Passagem de parâmetros via linha de comando
;         em NASM a partir de um programa C. (VERSÃO 32 BITS)
;
;   Este módulo recebe, de um programa C, o "argc" e o "argv" exatamente como
;   chegam à função main() do C. Ele percorre o vetor argv e apenas LISTA
;   (imprime) cada argumento recebido, usando a função da libc printf.
; ============================================================================

BITS 32

section .rodata

    fmt_argc        db "Total de argumentos (argc): %d", 10, 0

    fmt_arg         db '  argv[%d] = "%s"', 10, 0

    fmt_empty       db "Nenhum argumento para processar.", 10, 0

section .text

    global process_args

    extern printf

process_args:
    push    ebp                ; salva EBP do chamador
    mov     ebp, esp           ; novo frame de pilha: EBP aponta para o topo

    push    ebx                 ; preserva EBX do chamador
    push    esi                 ; preserva ESI do chamador
    push    edi                 ; preserva EDI do chamador

    mov     ebx, [ebp + 8]      ; EBX = argc
    mov     esi, [ebp + 12]     ; ESI = argv (endereço do vetor de ponteiros)

    cmp     ebx, 0
    jg      .tem_argumentos

    push    dword fmt_empty
    call    printf
    add     esp, 4              ; cdecl: o CHAMADOR desfaz o que empilhou (1 dword = 4 bytes)
    jmp     .fim

.tem_argumentos:
    push    ebx                 ; empilha argc (2º argumento do printf)
    push    dword fmt_argc       ; empilha o formato (1º argumento do printf)
    call    printf
    add     esp, 8               ; desfaz os 2 dwords empilhados (2 x 4 bytes)

    xor     edi, edi             ; EDI = i = 0

.loop_argv:
    cmp     edi, ebx             ; compara i com argc
    jge     .fim                 ; se i >= argc, encerra o laço

    mov     edx, [esi + edi*4]  ; EDX = argv[i] (endereço da string i)

    push    edx                  ; empilha argv[i] (3º arg do printf, na prática 2º vararg)
    push    edi                  ; empilha i (2º arg do printf, 1º vararg)
    push    dword fmt_arg         ; empilha o formato (1º arg do printf)
    call    printf
    add     esp, 12               ; desfaz os 3 dwords empilhados (3 x 4 bytes)

    inc     edi                   ; i++
    jmp     .loop_argv

.fim:
    pop     edi                   ; restaura EDI do chamador
    pop     esi                   ; restaura ESI do chamador
    pop     ebx                   ; restaura EBX do chamador
    pop     ebp                   ; restaura EBP do chamador (frame do chamador)
    ret                           ; retorna para quem chamou (main em C)
