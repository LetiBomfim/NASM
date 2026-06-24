set -e

PROG="./prog32"


if [ ! -x "$PROG" ]; then
    echo "ERRO: Rode 'make'!!"
    exit 1

fi

separador() {
    echo "------------------------------------"
}

teste() {
    local titulo="$1"
    shift
    separador
    echo "TESTE: $titulo"
    separador
    "$PROG" "$@"
    echo "(código de saída: $?)"
    echo
}

teste "Sem parâmetros"
teste "Um parâmetro simples" "ola"


teste "Múltiplos parâmetros" "primeiro" "segundo" "terceiro" "123"

LONGA=$(printf 'a%.0s' {1..200})
teste "String longa (200 caracteres)" "$LONGA"

teste "Parâmetro com espaços" "este é um argumento com espacos"
teste "Caracteres acentuados/especiais" "coração" "Ação_2026!"
teste "Parâmetro vazio" ""

separador
echo "Todos os testes foram executados!!"
separador
