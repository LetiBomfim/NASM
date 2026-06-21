; ============================================================================
; args32.asm
; ----------------------------------------------------------------------------
; Tarefa: Montador NASM #6 - Passagem de parâmetros via linha de comando
;         em NASM a partir de um programa C. (VERSÃO 32 BITS)
;
; Responsável: Pessoa 2 - "O Mestre do NASM"
;
; OBJETIVO:
;   Este módulo recebe, de um programa C, o "argc" e o "argv" exatamente como
;   chegam à função main() do C. Ele percorre o vetor argv e apenas LISTA
;   (imprime) cada argumento recebido, usando a função da libc printf.
;
; CONVENÇÃO DE CHAMADA EM x86 32 BITS (cdecl - padrão do GCC em Linux i386):
;   Diferente da versão 64 bits (onde os primeiros argumentos vão em
;   registradores RDI/RSI/...), em x86 de 32 bits TODOS os argumentos de
;   uma função são passados PELA PILHA, empilhados pelo chamador da
;   direita para a esquerda, antes do CALL.
;
;   Quando o C chama: process_args(argc, argv)
;     - O chamador empilha "argv" primeiro, depois "argc" (ordem inversa
;       à da chamada), e então executa CALL.
;     - O CALL empilha o endereço de retorno.
;
;   Dentro da função, IMEDIATAMENTE após o prólogo "push ebp / mov ebp,esp",
;   a pilha fica assim (crescendo para baixo, ou seja, endereços menores
;   no topo):
;
;       [ebp + 12]  -> argv   (2º parâmetro)
;       [ebp +  8]  -> argc   (1º parâmetro)
;       [ebp +  4]  -> endereço de retorno (empilhado pelo CALL)
;       [ebp +  0]  -> valor antigo de EBP (empilhado por "push ebp")
;
;   Por isso acessamos os parâmetros como [ebp+8] e [ebp+12], e NÃO via
;   registradores como na versão 64 bits.
;
; ALINHAMENTO DE PILHA:
;   Em x86 32 bits a exigência de alinhamento é mais branda que em 64 bits
;   (não há requisito rígido de 16 bytes imposto pela ABI para chamadas
;   simples de printf na prática em Linux/i386), mas mesmo assim mantemos
;   boas práticas: usamos PUSH/POP em pares e limpamos a pilha após cada
;   chamada (cdecl exige que o CHAMADOR limpe os argumentos empilhados,
;   diferente de outras convenções como stdcall).
; ============================================================================

BITS 32

; ----------------------------------------------------------------------------
; Seção de dados somente leitura: strings de formato usadas pelo printf
; ----------------------------------------------------------------------------
section .rodata
    ; Formato para imprimir o total de argumentos recebidos (argc).
    fmt_argc        db "Total de argumentos (argc): %d", 10, 0

    ; Formato para listar cada argumento: apenas índice e conteúdo
    ; (sem cálculo de comprimento, conforme solicitado).
    ; Usamos aspas simples para delimitar a string NASM, o que permite
    ; usar aspas duplas (") literalmente dentro do texto sem escape.
    fmt_arg         db '  argv[%d] = "%s"', 10, 0
    ; Resultado impresso, por exemplo:   argv[0] = "valor"

    ; Mensagem usada quando argc é 0 ou argv é nulo (defensivo)
    fmt_empty       db "Nenhum argumento para processar.", 10, 0

; ----------------------------------------------------------------------------
; Seção de código
; ----------------------------------------------------------------------------
section .text

    ; Declara process_args como GLOBAL (visível ao linker / chamável do C)
    global process_args

    ; printf é definida na libc; declaramos extern para o linker resolver.
    extern printf

; ----------------------------------------------------------------------------
; void process_args(int argc, char *argv[])
;
; Parâmetros (acessados via pilha, convenção cdecl):
;   [ebp + 8]  = argc
;   [ebp + 12] = argv  (vetor de ponteiros para char, 4 bytes cada em x86)
; ----------------------------------------------------------------------------
process_args:
    ; ------------------------------------------------------------------
    ; PRÓLOGO DA FUNÇÃO
    ; ------------------------------------------------------------------
    push    ebp                ; salva EBP do chamador
    mov     ebp, esp           ; novo frame de pilha: EBP aponta para o topo

    ; EBX, ESI, EDI são "callee-saved" em cdecl: se a função os usar, deve
    ; preservá-los. Vamos usar:
    ;   EBX -> guarda argc durante todo o processamento
    ;   ESI -> guarda argv (ponteiro para o vetor)
    ;   EDI -> usado como índice do laço (i)
    ; Todos sobrevivem a CALL printf, ao contrário de EAX/ECX/EDX
    ; (caller-saved, podem ser sobrescritos pela própria printf).
    push    ebx                 ; preserva EBX do chamador
    push    esi                 ; preserva ESI do chamador
    push    edi                 ; preserva EDI do chamador

    ; ------------------------------------------------------------------
    ; Lê os parâmetros da pilha (não há registradores de argumento em
    ; x86 32 bits cdecl -- tudo é lido a partir do frame apontado por EBP).
    ; ------------------------------------------------------------------
    mov     ebx, [ebp + 8]      ; EBX = argc
    mov     esi, [ebp + 12]     ; ESI = argv (endereço do vetor de ponteiros)

    ; ------------------------------------------------------------------
    ; Caso defensivo: se argc <= 0, não há nada para listar.
    ; ------------------------------------------------------------------
    cmp     ebx, 0
    jg      .tem_argumentos

    ; Empilha o argumento do printf (apenas o formato, sem argumentos
    ; variáveis) e chama printf. Em cdecl, quem empilha é sempre quem
    ; chama (aqui, esta própria função fazendo o papel de chamadora
    ; de printf).
    push    dword fmt_empty
    call    printf
    add     esp, 4              ; cdecl: o CHAMADOR desfaz o que empilhou (1 dword = 4 bytes)
    jmp     .fim

.tem_argumentos:
    ; ------------------------------------------------------------------
    ; Imprime o total de argumentos (argc) antes do laço:
    ;   printf(fmt_argc, argc)
    ;   Empilha-se da DIREITA para a ESQUERDA: primeiro o último
    ;   argumento (argc), depois o primeiro (fmt_argc).
    ; ------------------------------------------------------------------
    push    ebx                 ; empilha argc (2º argumento do printf)
    push    dword fmt_argc       ; empilha o formato (1º argumento do printf)
    call    printf
    add     esp, 8               ; desfaz os 2 dwords empilhados (2 x 4 bytes)

    ; ------------------------------------------------------------------
    ; LAÇO: percorre argv[0..argc-1], apenas listando cada argumento.
    ;   EDI será o índice "i" do laço.
    ; ------------------------------------------------------------------
    xor     edi, edi             ; EDI = i = 0

.loop_argv:
    cmp     edi, ebx             ; compara i com argc
    jge     .fim                 ; se i >= argc, encerra o laço

    ; --------------------------------------------------------------
    ; Lê argv[i]:
    ;   Em x86 de 32 bits, cada ponteiro ocupa 4 bytes (e não 8, como
    ;   em 64 bits). Por isso o deslocamento de cada elemento é i*4,
    ;   calculado com a notação de endereçamento [ESI + EDI*4]
    ;   (base ESI = argv, índice EDI = i, escala 4).
    ; --------------------------------------------------------------
    mov     edx, [esi + edi*4]  ; EDX = argv[i] (endereço da string i)

    ; --------------------------------------------------------------
    ; Imprime: índice e conteúdo do argumento (apenas listagem).
    ;   printf(fmt_arg, i, argv[i])
    ;   Empilha-se da direita para a esquerda: argv[i], depois i,
    ;   depois o formato.
    ; --------------------------------------------------------------
    push    edx                  ; empilha argv[i] (3º arg do printf, na prática 2º vararg)
    push    edi                  ; empilha i (2º arg do printf, 1º vararg)
    push    dword fmt_arg         ; empilha o formato (1º arg do printf)
    call    printf
    add     esp, 12               ; desfaz os 3 dwords empilhados (3 x 4 bytes)

    inc     edi                   ; i++
    jmp     .loop_argv

.fim:
    ; ------------------------------------------------------------------
    ; EPÍLOGO DA FUNÇÃO
    ; ------------------------------------------------------------------
    pop     edi                   ; restaura EDI do chamador
    pop     esi                   ; restaura ESI do chamador
    pop     ebx                   ; restaura EBX do chamador
    pop     ebp                   ; restaura EBP do chamador (frame do chamador)
    ret                           ; retorna para quem chamou (main em C)
