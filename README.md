# Trabalho de Software Básico (2026.1) - Prof. Marcelo Ladeira

Passagem de parâmetros via linha de comando em NASM (32 bits), chamado a partir de um programa em C. Sendo necessário a instalação de nasm e gcc-multilib para compilar

## Pré-requisitos

sudo apt-get install nasm gcc-multilib

## Como Executar

1. Compilar o projeto:
make

2. Executar o programa:
./prog32 arg1 arg2 arg3

3. Ver o resultado:
O programa lista o total de argumentos (argc) e o conteúdo de cada um (argv[i]).

## Rodar os testes

make test