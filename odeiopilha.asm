.data
    vetor: .double 123.5
    TAM: .word 2
    filename: .asciiz "output.txt"
    string: .space 20          # Buffer para armazenar o float convertido em string
    string2: .space 20 #string desenvertida
    dot_char: .asciiz "."       # Caractere para ponto decimal
    const_10: .double 10.0       # Constante de 10.0 para multiplicação
    erro_msg: .asciiz "Erro ao abrir o arquivo.\n"

.text
.globl main

main:
    # Abre o arquivo para escrita
    li $v0, 13
    la $a0, filename
    li $a1, 0
    syscall
    move $t0, $v0 # Guarda o descritor do arquivo em $t0

    # Carrega o endereço do vetor e o tamanho
    la $s0, vetor
    la $t1, TAM
    lw $t1, 0($t1)
    li $t2, 0                    # Índice do vetor

loop:
    beq $t2, $t1, fimloop        # Verifica se atingiu o final do vetor
    l.d $f12, 0($s0)             # Carrega o valor do vetor em $f12

    # Converte a parte inteira do float
    trunc.w.d $f0, $f12
    mfc1 $a1, $f0
    la $a0, string
    
int_to_string:
#    move $t0, $a0
    li $t5, 0

    # Se o número é zero, escreve '0'
#    beqz $a1, int_zero_case

    li $t3, 35
    sb $t3, 0($a0) #coloca # no comeco da string para declarar que é o comeco
    addi $t5, $t5, 1
    addi $a0, $a0, 1

int_to_string_loop:
    li $t4, 10
    div $a1, $t4 #divide por 10
    mfhi $t3 #resto
    mflo $a1 #quociente
    
    addi $t3, $t3, 48
    sb $t3, 0($a0)
    addi $t5, $t5, 1 #numero de caracteres
    addi $a0, $a0, 1
    
    bnez $a1, int_to_string_loop #continua o loop enquanto o quociente for !=0
    
    
    la $a2, string2
    
inverte_string:
    subi $a0, $a0, 1
    lb $t4, 0($a0)
    
    beq $t4, 35, escreve_arquivo #se o byte carregado for #, finaliza
    
    sb $t4, 0($a2)
    addi $a2, $a2, 1
    
    j inverte_string
    
escreve_arquivo:
    subi $t5, $t5, 1  # Reduz o tamanho para não incluir `#`
        # Syscall para escrever no arquivo
    li $v0, 15                    # Código de syscall para escrever
    move $a0, $t0                 # Descritor do arquivo em $a0
    la $a1, string2     # Endereço dos dados a serem escritos
    move $a2, $t5                   # Número de bytes a escrever ue precisa disso aqui?
    syscall



    # Verificando o código de retorno de syscall 15
bltz $v0, erro_escrita  # Se o valor de $v0 for negativo, ocorreu erro na escrita

# Continuação do código



 #   addi $t3, $t3, 1 sei la oq q isso aqui faz


    # Adiciona ponto decimal ao buffer

fimloop:
    # Fecha o arquivo
    li $v0, 16
    move $a0, $t0
    syscall

    # Finaliza o programa
    li $v0, 10
    syscall
    
    erro_escrita:
    # Imprimir mensagem de erro
    li $v0, 4
    la $a0, erro_msg  # Mensagem de erro
    syscall
    li $v0, 10  # Finalizar o programa
    syscall
